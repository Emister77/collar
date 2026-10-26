import Foundation
import SwiftData

/// The user's dietary profile. Only one record exists; it's saved on the device with SwiftData.
@Model
final class DietProfile {
    /// Raw values of `DietaryRestriction` (e.g. "vegan", "peanuts").
    var restrictionIDs: [String]
    /// Extra ingredients the user never wants to see, e.g. "mushrooms".
    var customExclusions: [String]
    /// Raw values of `NutritionGoal`.
    var goalIDs: [String]
    var calorieLimit: Int
    /// true = hide recipes that don't fit; false = show them with a warning badge.
    var hideConflicts: Bool

    init(restrictionIDs: [String] = [], customExclusions: [String] = [], goalIDs: [String] = [],
         calorieLimit: Int = 600, hideConflicts: Bool = true) {
        self.restrictionIDs = restrictionIDs
        self.customExclusions = customExclusions
        self.goalIDs = goalIDs
        self.calorieLimit = calorieLimit
        self.hideConflicts = hideConflicts
    }
}
