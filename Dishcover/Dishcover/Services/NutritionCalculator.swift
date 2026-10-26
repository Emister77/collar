import Foundation

/// Estimates a recipe's macros entirely on the device — no internet or outside service needed.
///
/// For each ingredient: the measure is turned into grams (`MeasureParser`), the ingredient is
/// looked up in Dishcover's built-in nutrition list (`NutritionFacts`, values per 100 g), and
/// grams / 100 × macros are added to the total.
enum NutritionCalculator {

    static func estimate(for recipe: Recipe) -> MacroEstimate {
        var total = Macros.zero
        var items: [IngredientNutrition] = []

        for ingredient in recipe.ingredients {
            guard let amount = MeasureParser.amount(for: ingredient) else {
                items.append(IngredientNutrition(name: ingredient.name, measure: ingredient.measure,
                                                 grams: nil, macros: nil, status: .unclearAmount))
                continue
            }
            if amount.grams == 0 {
                items.append(IngredientNutrition(name: ingredient.name, measure: ingredient.measure,
                                                 grams: 0, macros: .zero, status: .negligible))
                continue
            }
            guard let per100g = NutritionFacts.per100g(for: ingredient.name) else {
                items.append(IngredientNutrition(name: ingredient.name, measure: ingredient.measure,
                                                 grams: amount.grams, macros: nil, status: .notInList))
                continue
            }
            let macros = per100g.scaled(by: amount.grams / 100)
            total = total + macros
            items.append(IngredientNutrition(name: ingredient.name, measure: ingredient.measure,
                                             grams: amount.grams, macros: macros,
                                             status: .counted(assumedAmount: amount.assumed)))
        }
        return MacroEstimate(total: total, items: items)
    }
}
