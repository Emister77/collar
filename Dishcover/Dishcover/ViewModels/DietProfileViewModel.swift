import Foundation
import Observation
import SwiftData

/// Manages the user's diets, allergies, custom exclusions and nutrition goals,
/// and checks recipes against them.
@MainActor
@Observable
final class DietProfileViewModel {
    private(set) var restrictions: Set<DietaryRestriction> = []
    private(set) var customExclusions: [String] = []
    private(set) var goals: Set<NutritionGoal> = []
    private(set) var calorieLimit = 600
    private(set) var hideConflicts = true

    private let context: ModelContext
    private var profile: DietProfile

    init(context: ModelContext) {
        self.context = context
        if let existing = try? context.fetch(FetchDescriptor<DietProfile>()).first {
            profile = existing
        } else {
            profile = DietProfile()
            context.insert(profile)
            try? context.save()
        }
        loadFromProfile()
    }

    /// True if the user has set anything up.
    var isActive: Bool { !restrictions.isEmpty || !customExclusions.isEmpty || !goals.isEmpty }

    /// e.g. "Vegan · Peanuts · Low-Carb"
    var summary: String {
        let names = DietaryRestriction.allCases.filter(restrictions.contains).map(\.title)
            + customExclusions.map { "No \($0)" }
            + NutritionGoal.allCases.filter(goals.contains).map(\.shortTitle)
        return names.isEmpty ? "None set" : names.joined(separator: " · ")
    }

    // MARK: - Editing

    func toggle(_ restriction: DietaryRestriction) {
        if restrictions.contains(restriction) { restrictions.remove(restriction) } else { restrictions.insert(restriction) }
        save()
    }

    func toggle(_ goal: NutritionGoal) {
        if goals.contains(goal) { goals.remove(goal) } else { goals.insert(goal) }
        save()
    }

    func setCalorieLimit(_ value: Int) {
        calorieLimit = min(max(value, 100), 2000)
        save()
    }

    func setHideConflicts(_ hide: Bool) {
        hideConflicts = hide
        save()
    }

    func addExclusion(_ text: String) {
        let words = text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && !customExclusions.contains($0) }
        customExclusions.append(contentsOf: words)
        save()
    }

    func removeExclusion(_ word: String) {
        customExclusions.removeAll { $0 == word }
        save()
    }

    // MARK: - Checking recipes

    /// Every restriction or exclusion the recipe breaks, with the ingredients that cause it.
    func conflicts(for recipe: Recipe) -> [DietConflict] {
        var result: [DietConflict] = []
        for restriction in DietaryRestriction.allCases where restrictions.contains(restriction) {
            let bad = restriction.violations(in: recipe)
            if !bad.isEmpty { result.append(DietConflict(label: restriction.title, ingredients: bad)) }
        }
        for word in customExclusions {
            let bad = recipe.ingredients.map(\.name).filter { DietaryRestriction.name($0, matchesAnyOf: [word]) }
            if !bad.isEmpty { result.append(DietConflict(label: "No \(word)", ingredients: bad)) }
        }
        return result
    }

    /// Names of the ingredients that cause any conflict (used to highlight rows on the details screen).
    func flaggedIngredients(for recipe: Recipe) -> Set<String> {
        Set(conflicts(for: recipe).flatMap(\.ingredients))
    }

    /// Goals the recipe misses, given its per-serving macros. Empty if macros aren't known yet.
    func missedGoals(for macros: Macros?) -> [NutritionGoal] {
        guard let macros else { return [] }
        return NutritionGoal.allCases.filter { goals.contains($0) && !$0.isMet(by: macros, calorieLimit: calorieLimit) }
    }

    // MARK: - Persistence

    private func loadFromProfile() {
        restrictions = Set(profile.restrictionIDs.compactMap(DietaryRestriction.init(rawValue:)))
        customExclusions = profile.customExclusions
        goals = Set(profile.goalIDs.compactMap(NutritionGoal.init(rawValue:)))
        calorieLimit = profile.calorieLimit
        hideConflicts = profile.hideConflicts
    }

    private func save() {
        profile.restrictionIDs = restrictions.map(\.rawValue)
        profile.customExclusions = customExclusions
        profile.goalIDs = goals.map(\.rawValue)
        profile.calorieLimit = calorieLimit
        profile.hideConflicts = hideConflicts
        try? context.save()
    }
}
