import Foundation
import Observation

/// Provides macro estimates for recipes (results, details, random) and remembers the number
/// of servings the user picked. Estimates are calculated on the device, so they're instant.
@MainActor
@Observable
final class NutritionViewModel {
    /// Calculated estimates keyed by recipe id. Not observed: it's only a cache, and filling it
    /// while a view is drawing must not trigger another redraw.
    @ObservationIgnored private var cache: [String: MacroEstimate] = [:]
    /// Servings chosen by the user on the details screen, keyed by recipe id.
    private var servingsByRecipe: [String: Int] = [:]

    func estimate(for recipe: Recipe) -> MacroEstimate {
        if let cached = cache[recipe.id] { return cached }
        let estimate = NutritionCalculator.estimate(for: recipe)
        cache[recipe.id] = estimate
        return estimate
    }

    /// Per-serving macros, or nil if none of the ingredients could be counted.
    func perServing(for recipe: Recipe) -> Macros? {
        let estimate = estimate(for: recipe)
        return estimate.hasData ? estimate.perServing(servings(for: recipe.id)) : nil
    }

    func servings(for recipeID: String) -> Int {
        servingsByRecipe[recipeID] ?? MacroEstimate.defaultServings
    }

    func setServings(_ servings: Int, for recipeID: String) {
        servingsByRecipe[recipeID] = min(max(servings, 1), 12)
    }
}
