import SwiftUI
import MapKit

/// Map of nearby grocery stores, shown when a recipe has missing ingredients.
/// Uses the user's location only after they grant permission; without it, the user can
/// move the map anywhere and tap "Search this area".
struct StoreMapView: View {
    let missingIngredients: [String]

    @State private var viewModel = StoreMapViewModel()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selection: MKMapItem?
    /// The part of the map currently on screen, used by "Search this area".
    @State private var visibleRegion: MKCoordinateRegion?

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Map(position: $position, selection: $selection) {
                    UserAnnotation()
                    ForEach(viewModel.stores, id: \.self) { store in
                        Marker(store.name ?? "Store", systemImage: "cart.fill", coordinate: store.placemark.coordinate)
                            .tint(.orange)
                            .tag(store)
                    }
                }
                .mapControls { MapUserLocationButton() }
                .onMapCameraChange(frequency: .onEnd) { context in
                    visibleRegion = context.region
                }

                Button {
                    searchVisibleArea()
                } label: {
                    Label("Search this area", systemImage: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.bottom, 10)
                .disabled(visibleRegion == nil || viewModel.status == .searching)
            }
            .frame(height: 320)

            List {
                if let message = viewModel.message {
                    Section {
                        Label(message, systemImage: viewModel.status == .locating || viewModel.status == .waitingForPermission
                              ? "location.circle" : "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(viewModel.status == .locating || viewModel.status == .waitingForPermission
                                             ? Color.secondary : Color.orange)
                        if viewModel.canOpenSettings {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        if viewModel.canRetry {
                            Button("Try Again") { viewModel.retry() }
                        }
                    }
                }

                if !missingIngredients.isEmpty {
                    Section("You still need") {
                        Text(missingIngredients.joined(separator: ", "))
                            .font(.subheadline)
                    }
                }

                Section(viewModel.status == .searching ? "Searching…" : "Nearby grocery stores") {
                    ForEach(viewModel.stores, id: \.self) { store in
                        Button {
                            selection = store
                            position = .item(store)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(store.name ?? "Store").font(.headline)
                                    Text(store.placemark.title ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if let distance = viewModel.distanceText(for: store) {
                                    Text(distance).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Directions") {
                                store.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Grocery Stores")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.start() }
        .onChange(of: viewModel.userLocation?.latitude) {
            // Once the user's location is known, zoom the map to the stores around them.
            if viewModel.userLocation != nil { position = .automatic }
        }
    }

    private func searchVisibleArea() {
        guard let region = visibleRegion else { return }
        // Search radius roughly matches what's on screen (MapKit caps very large areas).
        let radius = region.span.latitudeDelta * 111_000
        Task {
            await viewModel.searchNearbyStores(around: region.center, radiusMeters: radius)
            position = .automatic
        }
    }
}
