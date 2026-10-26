import Foundation
import SwiftData

/// An ingredient the user has at home. Saved on-device with SwiftData so the
/// pantry doesn't have to be re-entered every time the app launches.
@Model
final class PantryItem {
    @Attribute(.unique) var name: String
    var dateAdded: Date
    /// Set only when the user moves the item to a different food group by hand
    /// (raw value of `FoodGroup`); otherwise the group is worked out from the name.
    var groupOverride: String?

    init(name: String, dateAdded: Date = .now, groupOverride: String? = nil) {
        self.name = name
        self.dateAdded = dateAdded
        self.groupOverride = groupOverride
    }

    /// The food group shown in the pantry (the user's choice, or the automatic one).
    var group: FoodGroup {
        groupOverride.flatMap(FoodGroup.init(rawValue:)) ?? FoodGroup.classify(name)
    }

    /// Icon shown next to the ingredient, e.g. 🍗 for chicken.
    var emoji: String {
        FoodGroup.emoji(for: name, group: group)
    }
}
