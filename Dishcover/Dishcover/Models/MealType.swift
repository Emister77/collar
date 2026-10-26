import Foundation

/// The kind of meal the user is in the mood for.
///
/// TheMealDB has no "meal type" field, so each type is matched using a mix of
/// TheMealDB categories (e.g. "Breakfast", "Dessert"), recipe tags (e.g. "Snack"),
/// and keywords in the recipe name (e.g. "sandwich", "burger", "wrap").
enum MealType: String, CaseIterable, Identifiable {
    case any = "Any"
    case breakfast = "Breakfast"
    case main = "Main"
    case snack = "Snack"
    case sandwich = "Sandwich"
    case dessert = "Dessert"
    case side = "Side"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .any: return "square.grid.2x2"
        case .breakfast: return "sunrise"
        case .main: return "fork.knife"
        case .snack: return "carrot"
        case .sandwich: return "takeoutbag.and.cup.and.straw"
        case .dessert: return "birthday.cake"
        case .side: return "leaf"
        }
    }

    /// TheMealDB categories that belong to this type (used with `filter.php?c=`).
    var categories: [String] {
        switch self {
        case .any, .sandwich: return []
        case .breakfast: return ["Breakfast"]
        case .main: return ["Beef", "Chicken", "Goat", "Lamb", "Pasta", "Pork", "Seafood", "Vegan", "Vegetarian", "Miscellaneous"]
        case .snack: return ["Starter", "Side"]
        case .dessert: return ["Dessert"]
        case .side: return ["Side"]
        }
    }

    /// Words in a recipe's name that suggest this type.
    var nameKeywords: [String] {
        switch self {
        case .any, .main, .side: return []
        case .breakfast:
            return ["pancake", "omelette", "omelet", "porridge", "waffle", "granola", "french toast",
                    "breakfast", "muffin", "benedict", "shakshuka", "frittata", "crepe", "scrambled"]
        case .snack:
            return ["dip", "bites", "chips", "popcorn", "nachos", "samosa", "spring roll", "wings",
                    "fritter", "bruschetta", "hummus", "skewer", "puff puff", "chin chin"]
        case .sandwich:
            return ["sandwich", "burger", "wrap", "toastie", "panini", "bagel", "quesadilla",
                    "sloppy joe", "hot dog", "banh mi", "bánh mì", "sub roll", "shawarma", "gyro"]
        case .dessert:
            return ["cake", "pie", "tart", "pudding", "cookie", "brownie", "ice cream", "cheesecake"]
        }
    }

    /// Recipe tags (`strTags`) that suggest this type.
    var tagKeywords: [String] {
        switch self {
        case .any, .main: return []
        case .breakfast: return ["breakfast", "brunch"]
        case .snack: return ["snack", "treat", "fingerfood", "streetfood"]
        case .sandwich: return ["sandwich", "burger"]
        case .dessert: return ["dessert", "pudding", "cake", "sweet", "baking"]
        case .side: return ["sidedish", "side"]
        }
    }

    /// Quick check on a search result that only has a name (before the full recipe is fetched).
    func nameSuggestsType(_ name: String) -> Bool {
        let lower = name.lowercased()
        return nameKeywords.contains { lower.contains($0) }
    }

    /// Full check once the complete recipe (category, tags, name) is known.
    func matches(_ recipe: Recipe) -> Bool {
        if self == .any { return true }
        if let category = recipe.category, categories.contains(category) { return true }
        let tags = recipe.tags.map { $0.lowercased() }
        if tags.contains(where: { tag in tagKeywords.contains(where: { tag.contains($0) }) }) { return true }
        return nameSuggestsType(recipe.name)
    }
}
