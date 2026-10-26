import Foundation

/// A diet or allergy the user can turn on in My Diet.
///
/// Each restriction has a list of ingredient keywords. A recipe breaks the restriction if any
/// of its ingredient names contains one of those words (matched on whole words, so "egg"
/// doesn't match "eggplant"). Some keywords are "hidden" sources, e.g. Worcestershire sauce
/// contains anchovies and soy sauce usually contains wheat.
enum DietaryRestriction: String, CaseIterable, Identifiable, Codable {
    // Diets
    case vegetarian, vegan, pescatarian, glutenFree, noPork, noAlcohol
    // The 9 major US food allergens
    case peanuts, treeNuts, dairy, eggs, fish, shellfish, soy, wheat, sesame

    var id: String { rawValue }

    enum Kind { case diet, allergy }

    var kind: Kind {
        switch self {
        case .vegetarian, .vegan, .pescatarian, .glutenFree, .noPork, .noAlcohol: return .diet
        default: return .allergy
        }
    }

    static var diets: [DietaryRestriction] { allCases.filter { $0.kind == .diet } }
    static var allergies: [DietaryRestriction] { allCases.filter { $0.kind == .allergy } }

    var title: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .pescatarian: return "Pescatarian"
        case .glutenFree: return "Gluten-Free"
        case .noPork: return "No Pork"
        case .noAlcohol: return "No Alcohol"
        case .peanuts: return "Peanuts"
        case .treeNuts: return "Tree Nuts"
        case .dairy: return "Dairy (Milk)"
        case .eggs: return "Eggs"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .soy: return "Soy"
        case .wheat: return "Wheat"
        case .sesame: return "Sesame"
        }
    }

    /// Ingredient words that break this restriction.
    var keywords: [String] {
        switch self {
        case .vegetarian: return Keywords.meat + Keywords.fish + Keywords.shellfish
        case .vegan: return Keywords.meat + Keywords.fish + Keywords.shellfish + Keywords.dairy + Keywords.eggs + ["honey"]
        case .pescatarian: return Keywords.meat
        case .glutenFree: return Keywords.wheat + ["barley", "rye", "spelt", "malt", "stock cube", "bouillon"]
        case .noPork: return Keywords.pork
        case .noAlcohol: return Keywords.alcohol
        case .peanuts: return ["peanut", "peanuts", "peanut butter", "peanut oil", "satay"]
        case .treeNuts: return Keywords.treeNuts
        case .dairy: return Keywords.dairy
        case .eggs: return Keywords.eggs
        case .fish: return Keywords.fish
        case .shellfish: return Keywords.shellfish
        case .soy: return ["soy", "soya", "soy sauce", "tofu", "tempeh", "miso", "edamame", "hoisin", "tamari", "teriyaki"]
        case .wheat: return Keywords.wheat
        case .sesame: return ["sesame", "sesame seeds", "sesame oil", "tahini", "hummus", "halva"]
        }
    }

    /// Ingredient names that contain a keyword but are actually fine
    /// (e.g. "coconut milk" for dairy, "rice flour" for wheat).
    var exceptions: [String] {
        switch self {
        case .dairy:
            return Exceptions.dairy
        case .vegan:
            return Exceptions.dairy + Exceptions.meat
        case .wheat, .glutenFree:
            return ["rice flour", "almond flour", "coconut flour", "cornflour", "corn flour", "gram flour",
                    "chickpea flour", "tapioca flour", "buckwheat", "rice noodles", "rice vermicelli", "corn tortilla"]
        case .vegetarian, .pescatarian:
            return Exceptions.meat
        default:
            return []
        }
    }

    private enum Exceptions {
        static let dairy = ["coconut milk", "coconut cream", "almond milk", "oat milk", "soy milk", "soya milk",
                            "rice milk", "peanut butter", "almond butter", "cocoa butter", "cream of tartar", "butter beans"]
        static let meat = ["kidney beans", "vegetable stock"]
    }

    /// Ingredient names in a recipe that break this restriction.
    func violations(in recipe: Recipe) -> [String] {
        recipe.ingredients.map(\.name).filter { DietaryRestriction.name($0, matchesAnyOf: keywords, except: exceptions) }
    }

    /// Whole-word match: "egg" matches "Eggs" and "Egg Yolks" but not "Eggplant".
    static func name(_ ingredient: String, matchesAnyOf words: [String], except exceptions: [String] = []) -> Bool {
        let name = ingredient.lowercased()
        if exceptions.contains(where: { name.contains($0) }) { return false }
        return words.contains { word in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word) + "(s|es)?\\b"
            return name.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private enum Keywords {
        static let pork = ["pork", "bacon", "ham", "sausage", "sausages", "chorizo", "pancetta", "prosciutto",
                           "salami", "pepperoni", "lard", "gelatin", "gelatine", "gammon"]
        static let meat = pork + ["beef", "chicken", "lamb", "mutton", "goat", "veal", "turkey", "duck", "venison",
                                  "mince", "minced beef", "steak", "brisket", "ribs", "oxtail", "liver", "kidney",
                                  "meatballs", "suet", "chicken stock", "beef stock", "lamb stock", "bone broth"]
        static let fish = ["fish", "salmon", "tuna", "cod", "haddock", "anchovy", "anchovies", "sardines", "mackerel",
                           "trout", "tilapia", "sea bass", "halibut", "monkfish", "snapper", "kipper", "fish sauce",
                           "worcestershire"]
        static let shellfish = ["shrimp", "prawn", "prawns", "crab", "lobster", "mussels", "clams", "oyster", "oysters",
                                "oyster sauce", "scallops", "squid", "octopus", "crayfish"]
        static let dairy = ["milk", "butter", "cheese", "cream", "yogurt", "yoghurt", "ghee", "buttermilk", "mozzarella",
                            "parmesan", "cheddar", "feta", "ricotta", "mascarpone", "paneer", "creme fraiche",
                            "crème fraîche", "sour cream", "custard", "whey", "halloumi", "gruyere", "brie",
                            "camembert", "gorgonzola", "stilton", "pecorino", "ice cream", "pesto"]
        static let eggs = ["egg", "eggs", "egg yolks", "egg white", "mayonnaise", "meringue", "aioli", "hollandaise", "custard"]
        static let treeNuts = ["almond", "almonds", "cashew", "cashews", "walnut", "walnuts", "pecan", "pecans",
                               "hazelnut", "hazelnuts", "pistachio", "pistachios", "macadamia", "brazil nut",
                               "pine nuts", "marzipan", "pesto", "praline", "nutella", "frangipane", "amaretto"]
        static let wheat = ["wheat", "flour", "bread", "breadcrumbs", "pasta", "spaghetti", "penne", "lasagne",
                            "lasagna", "macaroni", "fettuccine", "linguine", "tagliatelle", "noodles", "couscous",
                            "semolina", "bulgur", "pastry", "puff pastry", "filo", "phyllo", "pita", "naan",
                            "baguette", "biscuits", "crackers", "soy sauce", "hoisin", "beer", "seitan", "panko",
                            "udon", "ramen", "tortilla", "tortillas", "brioche", "croissant"]
        static let alcohol = ["wine", "red wine", "white wine", "beer", "rum", "brandy", "vodka", "sherry", "whisky",
                              "whiskey", "bourbon", "cider", "sake", "mirin", "liqueur", "cognac", "tequila", "gin",
                              "marsala", "kirsch", "amaretto", "stout", "ale"]
    }
}

/// Goals checked against the estimated macros (per serving).
enum NutritionGoal: String, CaseIterable, Identifiable, Codable {
    case lowCarb, highProtein, calorieLimit

    var id: String { rawValue }

    static let lowCarbMaxGrams = 20.0
    static let highProteinMinGrams = 30.0

    var title: String {
        switch self {
        case .lowCarb: return "Low-Carb (≤ 20g carbs)"
        case .highProtein: return "High-Protein (≥ 30g protein)"
        case .calorieLimit: return "Calorie limit"
        }
    }

    var shortTitle: String {
        switch self {
        case .lowCarb: return "Low-Carb"
        case .highProtein: return "High-Protein"
        case .calorieLimit: return "Calorie limit"
        }
    }

    func isMet(by macros: Macros, calorieLimit: Int) -> Bool {
        switch self {
        case .lowCarb: return macros.carbs <= NutritionGoal.lowCarbMaxGrams
        case .highProtein: return macros.protein >= NutritionGoal.highProteinMinGrams
        case .calorieLimit: return macros.calories <= Double(calorieLimit)
        }
    }
}

/// One reason a recipe doesn't fit the user's profile, e.g. "Vegan: Butter, Eggs".
struct DietConflict: Hashable, Identifiable {
    var id: String { label }
    let label: String
    let ingredients: [String]

    var text: String { ingredients.isEmpty ? label : "\(label): \(ingredients.joined(separator: ", "))" }
}
