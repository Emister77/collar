import Foundation

/// Calories and macronutrients (grams of protein, carbs and fat).
struct Macros: Hashable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let zero = Macros(calories: 0, protein: 0, carbs: 0, fat: 0)

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(calories: lhs.calories + rhs.calories,
               protein: lhs.protein + rhs.protein,
               carbs: lhs.carbs + rhs.carbs,
               fat: lhs.fat + rhs.fat)
    }

    func scaled(by factor: Double) -> Macros {
        Macros(calories: calories * factor, protein: protein * factor, carbs: carbs * factor, fat: fat * factor)
    }

    /// e.g. "520 kcal · 38g protein · 45g carbs · 18g fat"
    var shortText: String {
        "\(Int(calories.rounded())) kcal · \(Int(protein.rounded()))g protein · \(Int(carbs.rounded()))g carbs · \(Int(fat.rounded()))g fat"
    }
}

/// How one ingredient line contributed to a recipe's estimate (shown in the breakdown screen).
struct IngredientNutrition: Hashable, Identifiable {
    enum Status: Hashable {
        /// Counted. `assumedAmount` is true when the measure was blank and a typical amount was used.
        case counted(assumedAmount: Bool)
        /// Too small to matter (salt, water, "to taste", a pinch).
        case negligible
        /// The measure couldn't be understood (e.g. "to cover", "for the sauce").
        case unclearAmount
        /// The ingredient isn't in Dishcover's nutrition list.
        case notInList
    }

    var id: String { name + measure }
    let name: String
    let measure: String
    let grams: Double?
    let macros: Macros?
    let status: Status

    var isCounted: Bool {
        switch status {
        case .counted, .negligible: return true
        case .unclearAmount, .notInList: return false
        }
    }

    var statusText: String {
        switch status {
        case .counted(let assumed): return assumed ? "Amount not listed – typical amount used" : "Counted"
        case .negligible: return "Too small to count"
        case .unclearAmount: return "Not counted – amount unclear"
        case .notInList: return "Not counted – not in Dishcover's nutrition list"
        }
    }
}

/// Estimated macros for a whole recipe, calculated on the device from each ingredient's
/// amount and Dishcover's built-in nutrition list.
struct MacroEstimate: Hashable {
    enum Confidence { case good, fair, rough }

    /// Macros for the entire recipe.
    let total: Macros
    let items: [IngredientNutrition]

    var countedIngredients: Int { items.filter(\.isCounted).count }
    var totalIngredients: Int { items.count }

    /// TheMealDB doesn't list servings, so the app assumes 4 unless the user changes it.
    static let defaultServings = 4

    func perServing(_ servings: Int) -> Macros {
        total.scaled(by: 1.0 / Double(max(servings, 1)))
    }

    /// Share of ingredients that were counted (or were too small to matter).
    var coverage: Double {
        totalIngredients == 0 ? 0 : Double(countedIngredients) / Double(totalIngredients)
    }

    var confidence: Confidence {
        switch coverage {
        case 0.85...: return .good
        case 0.6..<0.85: return .fair
        default: return .rough
        }
    }

    var confidenceLabel: String {
        switch confidence {
        case .good: return "Good estimate"
        case .fair: return "Fair estimate"
        case .rough: return "Rough estimate"
        }
    }

    /// True if there is something meaningful to show.
    var hasData: Bool { items.contains { if case .counted = $0.status { return true } else { return false } } }

    var coverageText: String {
        "Based on \(countedIngredients) of \(totalIngredients) ingredients."
    }
}
