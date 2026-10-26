import Foundation
import Observation

/// Gets recipes from TheMealDB, applies the cuisine / meal-type / cook-time filters and the
/// user's dietary profile, and compares each recipe to the user's pantry.
@MainActor
@Observable
final class RecipeSearchViewModel {
    enum Mode: String, CaseIterable, Identifiable {
        case name = "By Name"
        case ingredients = "By Ingredients"
        var id: String { rawValue }
    }

    var mode: Mode = .ingredients
    var query: String = ""
    var selectedIngredients: Set<String> = []

    // MARK: Filters
    /// Cuisines available from TheMealDB (`list.php?a=list`), loaded once.
    private(set) var cuisines: [String] = []
    /// nil = any cuisine.
    var selectedCuisine: String?
    var mealType: MealType = .any
    /// Estimated total time (see `Recipe.estimatedMinutes`).
    var cookTime: CookTimeRange = .any
    /// Apply the user's dietary profile to this search (can be turned off, e.g. when cooking for a friend).
    var respectDiet = true

    private(set) var results: [Recipe] = []
    private(set) var randomRecipe: Recipe?
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var hasSearched = false

    /// Ingredient search fans out one request per selected ingredient, then one
    /// lookup per meal, so we cap both to keep the free API happy.
    private let maxIngredientQueries = 5
    private let maxDetailLookups = 20
    /// Look up more meals when the diet is on, since some will be removed.
    private let maxDetailLookupsWithDiet = 30

    private let service: MealDBService
    private let diet: DietProfileViewModel
    private let nutrition: NutritionViewModel

    init(service: MealDBService = MealDBService(), diet: DietProfileViewModel, nutrition: NutritionViewModel) {
        self.service = service
        self.diet = diet
        self.nutrition = nutrition
    }

    /// True when recipes that break the profile should be removed (not just badged).
    private var hidingDietConflicts: Bool { respectDiet && diet.isActive && diet.hideConflicts }

    // MARK: - Filters

    var hasActiveFilters: Bool { selectedCuisine != nil || mealType != .any || cookTime != .any }

    /// Short description of the active filters, e.g. "Italian · Breakfast · Under 15 min".
    var filterSummary: String {
        [selectedCuisine, mealType == .any ? nil : mealType.rawValue, cookTime == .any ? nil : cookTime.rawValue]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    func clearFilters() {
        selectedCuisine = nil
        mealType = .any
        cookTime = .any
    }

    func loadCuisines() async {
        guard cuisines.isEmpty else { return }
        cuisines = (try? await service.listCuisines()) ?? []
    }

    /// True if a full recipe passes every active filter.
    func passesFilters(_ recipe: Recipe) -> Bool {
        if let selectedCuisine, recipe.area != selectedCuisine { return false }
        if !mealType.matches(recipe) { return false }
        if !cookTime.contains(recipe.estimatedMinutes) { return false }
        if hidingDietConflicts && !diet.conflicts(for: recipe).isEmpty { return false }
        return true
    }

    /// Removes recipes that miss a nutrition goal (Low-Carb, High-Protein, calorie limit).
    /// Macros are calculated on the device; recipes with no countable ingredients are kept.
    private func applyNutritionGoals(_ recipes: [Recipe]) -> [Recipe] {
        guard hidingDietConflicts, !diet.goals.isEmpty else { return recipes }
        return recipes.filter { diet.missedGoals(for: nutrition.perServing(for: $0)).isEmpty }
    }

    // MARK: - Search by name

    func searchByName() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        await run {
            let recipes = try await self.service.searchByName(text)
            self.results = self.applyNutritionGoals(recipes.filter(self.passesFilters))
        }
    }

    // MARK: - Search by ingredients

    /// 1. `filter.php?i=` for each ingredient (returns only id, name and image).
    /// 2. If a cuisine or meal type is chosen, `filter.php?a=` / `filter.php?c=` give the ids
    ///    that fit, and meals outside them are dropped *before* the expensive detail lookups.
    /// 3. Rank the remaining meals by how many of the selected ingredients they appeared under.
    /// 4. `lookup.php` for the top meals to get full ingredient lists + instructions.
    /// 5. Apply the full filters (tags, cook time, dietary profile) and sort by how much of each recipe the pantry covers.
    func searchByIngredients(pantry: [String]) async {
        let chosen = Array(selectedIngredients.isEmpty ? Set(pantry) : selectedIngredients)
            .prefix(maxIngredientQueries)
        guard !chosen.isEmpty else {
            errorMessage = "Add ingredients to your pantry first."
            return
        }

        await run {
            let service = self.service

            // Step 1: meals that use each ingredient.
            var hits: [String: Int] = [:]
            var names: [String: String] = [:]
            try await withThrowingTaskGroup(of: [MealSummary].self) { group in
                for ingredient in chosen {
                    group.addTask { try await service.filterByIngredient(ingredient) }
                }
                for try await summaries in group {
                    for meal in summaries {
                        hits[meal.idMeal, default: 0] += 1
                        names[meal.idMeal] = meal.strMeal
                    }
                }
            }

            // Step 2: narrow by cuisine and meal type using cheap list requests.
            if let cuisine = self.selectedCuisine {
                let cuisineIDs = Set(try await service.filterByCuisine(cuisine).map(\.idMeal))
                hits = hits.filter { cuisineIDs.contains($0.key) }
            }
            let type = self.mealType
            if type != .any {
                var typeIDs: Set<String> = []
                for category in type.categories {
                    typeIDs.formUnion(try await service.filterByCategory(category).map(\.idMeal))
                }
                hits = hits.filter { typeIDs.contains($0.key) || type.nameSuggestsType(names[$0.key] ?? "") }
            }

            // Steps 3–4: full details for the best candidates.
            let lookupLimit = self.hidingDietConflicts ? self.maxDetailLookupsWithDiet : self.maxDetailLookups
            let topIDs = hits.sorted { $0.value > $1.value }
                .prefix(lookupLimit)
                .map(\.key)

            var recipes: [Recipe] = []
            try await withThrowingTaskGroup(of: Recipe?.self) { group in
                for id in topIDs {
                    group.addTask { try await service.lookup(id: id) }
                }
                for try await recipe in group {
                    if let recipe { recipes.append(recipe) }
                }
            }

            // Step 5: final filters (tags, cook time, diet), nutrition goals, then sort by pantry match.
            let filtered = self.applyNutritionGoals(recipes.filter(self.passesFilters))
            self.results = filtered
                .sorted { Self.match($0, pantry: pantry).fraction > Self.match($1, pantry: pantry).fraction }
        }
    }

    // MARK: - Random

    func fetchRandom() async {
        await run {
            self.randomRecipe = try await self.service.random()
        }
    }

    // MARK: - Pantry matching

    /// Splits a recipe's ingredients into the ones the user has and the ones they're missing.
    /// Matching is loose so "chicken" in the pantry covers "Chicken Breast" in a recipe.
    nonisolated static func match(_ recipe: Recipe, pantry: [String]) -> PantryMatch {
        let owned = pantry.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        var have: [Ingredient] = []
        var missing: [Ingredient] = []
        for ingredient in recipe.ingredients {
            let name = ingredient.name.lowercased()
            if owned.contains(where: { !$0.isEmpty && (name.contains($0) || $0.contains(name)) }) {
                have.append(ingredient)
            } else {
                missing.append(ingredient)
            }
        }
        return PantryMatch(have: have, missing: missing)
    }

    // MARK: - Helpers

    private func run(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasSearched = true
        }
        do {
            try await work()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
