import Foundation

/// One ingredient line of a recipe, e.g. "Chicken Breast" / "2 lbs".
struct Ingredient: Codable, Hashable, Identifiable {
    var id: String { name + measure }
    let name: String
    let measure: String
}

/// A full recipe as returned by TheMealDB `search.php`, `lookup.php` and `random.php`.
///
/// TheMealDB stores ingredients as 20 flat keys (`strIngredient1` ... `strIngredient20`
/// and `strMeasure1` ... `strMeasure20`), so decoding collapses them into `ingredients`.
struct Recipe: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let category: String?
    let area: String?
    let instructions: String
    let thumbnailURL: URL?
    let youtubeURL: URL?
    let ingredients: [Ingredient]
    /// Comma-separated `strTags` from TheMealDB, e.g. ["Breakfast", "Snack"]. Used by the meal-type filter.
    let tags: [String]

    /// Instructions split into individual steps for display.
    var steps: [String] {
        instructions
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            // drop empty lines and bare "STEP 1"-style headings
            .filter { !$0.isEmpty && $0.range(of: #"^(?i)step\s*\d+\.?$"#, options: .regularExpression) == nil }
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(_ string: String) { stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicKey.self)
        func string(_ key: String) -> String? {
            let value = (try? c.decodeIfPresent(String.self, forKey: DynamicKey(key))) ?? nil
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }

        id = string("idMeal") ?? UUID().uuidString
        name = string("strMeal") ?? "Untitled Recipe"
        category = string("strCategory")
        area = string("strArea")
        instructions = string("strInstructions") ?? ""
        thumbnailURL = string("strMealThumb").flatMap(URL.init(string:))
        youtubeURL = string("strYoutube").flatMap(URL.init(string:))
        tags = (string("strTags") ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var list: [Ingredient] = []
        for i in 1...20 {
            if let ingredientName = string("strIngredient\(i)") {
                list.append(Ingredient(name: ingredientName, measure: string("strMeasure\(i)") ?? ""))
            }
        }
        ingredients = list
    }

    /// Memberwise initializer (used by previews / tests).
    init(id: String, name: String, category: String?, area: String?, instructions: String,
         thumbnailURL: URL?, youtubeURL: URL?, ingredients: [Ingredient], tags: [String] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.area = area
        self.instructions = instructions
        self.thumbnailURL = thumbnailURL
        self.youtubeURL = youtubeURL
        self.ingredients = ingredients
        self.tags = tags
    }
}

/// The short result returned by `filter.php?i=` (ingredient search): only id, name and image.
/// A second `lookup.php?i=<id>` request is needed to get the full `Recipe`.
struct MealSummary: Decodable, Hashable {
    let idMeal: String
    let strMeal: String
    let strMealThumb: String?
}

/// TheMealDB wraps every response as `{ "meals": [...] }` and returns `null` when nothing matches.
struct MealsResponse<T: Decodable>: Decodable {
    let meals: [T]?
}

/// How well a recipe matches what the user has in their pantry.
struct PantryMatch: Hashable {
    let have: [Ingredient]
    let missing: [Ingredient]

    var total: Int { have.count + missing.count }
    var fraction: Double { total == 0 ? 0 : Double(have.count) / Double(total) }
    var summary: String { "You have \(have.count) of \(total) ingredients" }
}
