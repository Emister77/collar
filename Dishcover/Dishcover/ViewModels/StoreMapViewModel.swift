import Foundation
import Observation
import CoreLocation
import MapKit

/// Asks for location permission and finds grocery stores near the user with MapKit.
/// If location isn't available, the user can still search any area they move the map to.
@MainActor
@Observable
final class StoreMapViewModel: NSObject {
    enum Status: Equatable {
        case waitingForPermission
        case locating
        case searching
        case ready
        /// Location is turned off for the app (the user tapped Don't Allow, or Settings).
        case denied
        /// The app has no location permission text in Info.plist, so iOS never asks.
        case missingUsageDescription
        /// Permission is fine but no position arrived (e.g. Simulator location set to None).
        case noLocation
        case failed(String)
    }

    private(set) var stores: [MKMapItem] = []
    private(set) var status: Status = .waitingForPermission
    private(set) var userLocation: CLLocationCoordinate2D?
    /// Where the last store search was centred (the user's location or the map area).
    private(set) var searchCenter: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Plain-language explanation for the current status, or nil when nothing needs explaining.
    var message: String? {
        switch status {
        case .waitingForPermission: return "Waiting for location permission…"
        case .locating: return "Finding your location…"
        case .searching, .ready: return nil
        case .denied:
            return "Location is off for Dishcover. Turn it on in Settings, or move the map and tap “Search this area”."
        case .missingUsageDescription:
            return "Location can't be requested: add “Privacy - Location When In Use Usage Description” to the app's Info settings in Xcode. You can still move the map and tap “Search this area”."
        case .noLocation:
            return "Couldn't find your location. On the Simulator, choose Features → Location → Apple or Custom Location, then tap Try Again. Or move the map and tap “Search this area”."
        case .failed(let text): return text
        }
    }

    var canOpenSettings: Bool { status == .denied }
    var canRetry: Bool { status == .noLocation || status == .denied || isFailed }
    private var isFailed: Bool { if case .failed = status { return true } else { return false } }

    /// Asks for permission if needed, then gets the user's location. Never uses location without permission.
    func start() {
        guard Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil else {
            status = .missingUsageDescription
            return
        }
        handle(manager.authorizationStatus)
    }

    func retry() {
        if let userLocation {
            // Location is already known; the store search itself failed, so just search again.
            Task { await searchNearbyStores(around: userLocation) }
        } else {
            start()
        }
    }

    private func handle(_ authorization: CLAuthorizationStatus) {
        switch authorization {
        case .notDetermined:
            status = .waitingForPermission
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            beginLocating()
        case .denied, .restricted:
            stopLocating()
            status = .denied
        @unknown default:
            status = .denied
        }
    }

    /// Keeps listening until the first position arrives (more reliable than a one-off request,
    /// especially on the Simulator), and gives up with a helpful message after 10 seconds.
    private func beginLocating() {
        guard userLocation == nil else { return }   // already located on this visit
        status = .locating
        manager.startUpdatingLocation()
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, !Task.isCancelled, self.status == .locating else { return }
            self.stopLocating()
            self.status = .noLocation
        }
    }

    private func stopLocating() {
        manager.stopUpdatingLocation()
        timeoutTask?.cancel()
    }

    /// Searches for grocery stores around any point, e.g. the middle of the area the user is looking at.
    func searchNearbyStores(around coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance = 8000) async {
        status = .searching
        searchCenter = coordinate

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "grocery store"
        request.resultTypes = .pointOfInterest
        let radius = min(max(radiusMeters, 2000), 50000)
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: radius, longitudinalMeters: radius)

        do {
            let response = try await MKLocalSearch(request: request).start()
            let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            stores = response.mapItems.sorted { distance(of: $0, from: here) < distance(of: $1, from: here) }
            status = stores.isEmpty ? .failed("No grocery stores found here. Try moving the map and searching again.") : .ready
        } catch {
            stores = []
            status = .failed("Couldn't search for stores. Check your internet connection and try again.")
        }
    }

    /// Distance from the user (or from the searched area if the user's location is unknown).
    func distanceText(for item: MKMapItem) -> String? {
        guard let origin = userLocation ?? searchCenter else { return nil }
        let meters = distance(of: item, from: CLLocation(latitude: origin.latitude, longitude: origin.longitude))
        return String(format: "%.1f mi", meters / 1609.34)
    }

    private func distance(of item: MKMapItem, from location: CLLocation) -> CLLocationDistance {
        let c = item.placemark.coordinate
        return CLLocation(latitude: c.latitude, longitude: c.longitude).distance(from: location)
    }
}

extension StoreMapViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorization = manager.authorizationStatus
        Task { @MainActor in
            // Ignore the first callback that arrives before start() has been called.
            guard self.status != .missingUsageDescription else { return }
            self.handle(authorization)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            guard self.userLocation == nil else { return }   // only search once per visit
            self.stopLocating()
            self.userLocation = coordinate
            await self.searchNearbyStores(around: coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let code = (error as? CLError)?.code
        Task { @MainActor in
            switch code {
            case .denied:
                self.stopLocating()
                self.status = .denied
            case .locationUnknown:
                // Temporary: Core Location keeps trying, and the 10-second timeout handles giving up.
                break
            default:
                self.stopLocating()
                self.status = .noLocation
            }
        }
    }
}
