import Foundation

/// The food group a pantry ingredient belongs to, used to split the pantry into sections
/// and to pick an icon for each ingredient.
enum FoodGroup: String, CaseIterable, Identifiable, Codable {
    case meat, vegetables, fruits, dairy, grains, legumes, herbs, sauces, baking, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meat: return "Meat & Seafood"
        case .vegetables: return "Vegetables"
        case .fruits: return "Fruits"
        case .dairy: return "Dairy & Eggs"
        case .grains: return "Grains & Carbs"
        case .legumes: return "Beans, Nuts & Seeds"
        case .herbs: return "Herbs & Spices"
        case .sauces: return "Sauces, Oils & Stock"
        case .baking: return "Baking & Sweets"
        case .other: return "Other"
        }
    }

    /// Icon for the section header (and for ingredients without their own icon).
    var emoji: String {
        switch self {
        case .meat: return "🥩"
        case .vegetables: return "🥦"
        case .fruits: return "🍎"
        case .dairy: return "🧀"
        case .grains: return "🍞"
        case .legumes: return "🥜"
        case .herbs: return "🌿"
        case .sauces: return "🫙"
        case .baking: return "🍯"
        case .other: return "🛒"
        }
    }

    /// Picks a group from the ingredient's name. The longest matching keyword wins,
    /// so "peanut butter" is a nut (not dairy) and "egg noodles" is a grain (not an egg).
    static func classify(_ name: String) -> FoodGroup {
        let lower = name.lowercased()
        return groupKeywords.first { matches(lower, $0.0) }?.1 ?? .other
    }

    /// A specific icon for common ingredients (🍗 chicken, 🧄 garlic), or the group's icon.
    static func emoji(for name: String, group: FoodGroup) -> String {
        let lower = name.lowercased()
        return emojiKeywords.first { matches(lower, $0.0) }?.1 ?? group.emoji
    }

    private static func matches(_ name: String, _ keyword: String) -> Bool {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: keyword) + "(s|es)?\\b"
        return name.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Keyword tables

    private static let groupKeywords: [(String, FoodGroup)] = {
        let table: [FoodGroup: [String]] = [
            .meat: ["chicken", "beef", "pork", "lamb", "mutton", "goat", "veal", "turkey", "duck", "bacon", "ham",
                    "sausage", "chorizo", "salami", "pepperoni", "pancetta", "prosciutto", "mince", "mincemeat",
                    "ground beef", "steak", "brisket", "ribs", "venison", "liver", "meatballs", "fish", "salmon",
                    "tuna", "cod", "haddock", "trout", "mackerel", "sardine", "anchovy", "anchovies", "tilapia",
                    "sea bass", "halibut", "shrimp", "prawn", "crab", "lobster", "mussel", "clam", "scallop",
                    "squid", "octopus", "crayfish", "stockfish", "oyster"],
            .vegetables: ["onion", "garlic", "shallot", "leek", "spring onion", "green onion", "tomato", "potato",
                          "sweet potato", "carrot", "celery", "bell pepper", "red pepper", "green pepper",
                          "yellow pepper", "chilli", "chili", "jalapeno", "scotch bonnet", "mushroom", "spinach",
                          "kale", "lettuce", "cabbage", "broccoli", "cauliflower", "zucchini", "courgette",
                          "eggplant", "aubergine", "cucumber", "peas", "green beans", "corn", "sweetcorn",
                          "asparagus", "beetroot", "parsnip", "turnip", "squash", "pumpkin", "okra", "plantain",
                          "yam", "cassava", "artichoke", "fennel", "radish", "bok choy", "pak choi", "bean sprouts",
                          "arugula", "rocket", "watercress", "celeriac", "vegetable", "mixed vegetables"],
            .fruits: ["apple", "banana", "lemon", "lime", "orange", "mango", "pineapple", "pear", "peach", "plum",
                      "grape", "strawberry", "strawberries", "blueberry", "blueberries", "raspberry", "raspberries",
                      "cherry", "cherries", "avocado", "coconut", "dates", "raisins", "sultanas", "apricot", "fig",
                      "kiwi", "watermelon", "melon", "pomegranate", "cranberry", "cranberries", "olive"],
            .dairy: ["milk", "butter", "cheese", "cheddar", "mozzarella", "parmesan", "feta", "ricotta", "mascarpone",
                     "cream", "double cream", "heavy cream", "sour cream", "yogurt", "yoghurt", "ghee", "buttermilk",
                     "egg", "eggs", "creme fraiche", "crème fraîche", "paneer", "halloumi", "brie", "gruyere",
                     "custard", "ice cream"],
            .grains: ["rice", "pasta", "spaghetti", "penne", "macaroni", "lasagne", "lasagna", "fettuccine",
                      "linguine", "noodles", "egg noodles", "rice noodles", "bread", "flour", "oats", "couscous",
                      "quinoa", "bulgur", "barley", "tortilla", "pita", "pitta", "naan", "baguette", "breadcrumbs",
                      "cornmeal", "polenta", "semolina", "cereal", "cornflakes", "crackers", "pastry", "filo",
                      "puff pastry", "brioche", "bun", "wrap", "garri", "fufu"],
            .legumes: ["beans", "kidney beans", "black beans", "butter beans", "cannellini beans", "chickpeas",
                       "lentils", "split peas", "peanut", "peanut butter", "almond", "cashew", "walnut", "pecan",
                       "pistachio", "hazelnut", "pine nuts", "nuts", "sesame seed", "sunflower seed", "pumpkin seed",
                       "chia seed", "flaxseed", "tofu", "tempeh", "edamame", "hummus", "egusi", "black eyed beans"],
            .herbs: ["salt", "pepper", "black pepper", "cumin", "paprika", "turmeric", "cinnamon", "nutmeg", "oregano",
                     "thyme", "rosemary", "basil", "parsley", "coriander", "cilantro", "mint", "dill", "bay leaf",
                     "bay leaves", "chili powder", "chilli powder", "curry powder", "garam masala", "allspice",
                     "cardamom", "cloves", "ginger", "saffron", "star anise", "chives", "sage", "seasoning",
                     "cayenne", "mixed spice", "chili flakes", "chilli flakes"],
            .sauces: ["oil", "olive oil", "vegetable oil", "sesame oil", "coconut oil", "palm oil", "soy sauce",
                      "fish sauce", "oyster sauce", "hoisin", "worcestershire", "vinegar", "ketchup", "mustard",
                      "mayonnaise", "hot sauce", "sriracha", "bbq sauce", "barbecue sauce", "pesto", "salsa", "stock",
                      "broth", "stock cube", "chicken stock", "beef stock", "vegetable stock", "fish stock", "lamb stock", "tomato paste", "tomato puree", "passata", "coconut milk",
                      "coconut cream", "curry paste", "miso", "tahini", "wine", "beer", "sauce", "chopped tomatoes"],
            .baking: ["sugar", "brown sugar", "icing sugar", "caster sugar", "honey", "maple syrup", "syrup",
                      "chocolate", "cocoa", "vanilla", "baking powder", "baking soda", "bicarbonate of soda", "yeast",
                      "gelatin", "gelatine", "cornstarch", "cornflour", "jam", "molasses", "treacle", "marzipan",
                      "sprinkles"],
        ]
        return table.flatMap { group, words in words.map { ($0, group) } }
            .sorted { $0.0.count > $1.0.count }
    }()

    private static let emojiKeywords: [(String, String)] = [
        ("chicken", "🍗"), ("turkey", "🦃"), ("beef", "🥩"), ("steak", "🥩"), ("mince", "🥩"), ("ground beef", "🥩"),
        ("lamb", "🍖"), ("pork", "🍖"), ("ham", "🍖"), ("ribs", "🍖"), ("bacon", "🥓"), ("sausage", "🌭"),
        ("fish", "🐟"), ("salmon", "🐟"), ("tuna", "🐟"), ("cod", "🐟"), ("haddock", "🐟"), ("trout", "🐟"),
        ("mackerel", "🐟"), ("sardine", "🐟"), ("shrimp", "🦐"), ("prawn", "🦐"), ("crab", "🦀"), ("lobster", "🦞"),
        ("squid", "🦑"), ("octopus", "🦑"), ("oyster", "🦪"),
        ("egg", "🥚"), ("eggs", "🥚"), ("milk", "🥛"), ("butter", "🧈"), ("cheese", "🧀"), ("cheddar", "🧀"),
        ("mozzarella", "🧀"), ("parmesan", "🧀"), ("feta", "🧀"), ("yogurt", "🥣"), ("yoghurt", "🥣"),
        ("ice cream", "🍨"),
        ("rice", "🍚"), ("pasta", "🍝"), ("spaghetti", "🍝"), ("penne", "🍝"), ("macaroni", "🍝"), ("lasagne", "🍝"),
        ("noodles", "🍜"), ("bread", "🍞"), ("baguette", "🥖"), ("flour", "🌾"), ("oats", "🌾"), ("tortilla", "🫓"),
        ("pita", "🫓"), ("naan", "🫓"), ("pastry", "🥐"), ("croissant", "🥐"),
        ("potato", "🥔"), ("sweet potato", "🍠"), ("carrot", "🥕"), ("onion", "🧅"), ("spring onion", "🧅"),
        ("garlic", "🧄"), ("tomato", "🍅"), ("bell pepper", "🫑"), ("red pepper", "🫑"), ("green pepper", "🫑"),
        ("chilli", "🌶️"), ("chili", "🌶️"), ("jalapeno", "🌶️"), ("scotch bonnet", "🌶️"), ("mushroom", "🍄"),
        ("broccoli", "🥦"), ("lettuce", "🥬"), ("spinach", "🥬"), ("kale", "🥬"), ("cabbage", "🥬"),
        ("bok choy", "🥬"), ("pak choi", "🥬"), ("corn", "🌽"), ("sweetcorn", "🌽"), ("cucumber", "🥒"),
        ("eggplant", "🍆"), ("aubergine", "🍆"), ("peas", "🫛"), ("avocado", "🥑"), ("olive", "🫒"),
        ("olive oil", "🫒"), ("ginger", "🫚"),
        ("apple", "🍎"), ("banana", "🍌"), ("lemon", "🍋"), ("lime", "🍋"), ("orange", "🍊"), ("mango", "🥭"),
        ("pineapple", "🍍"), ("strawberry", "🍓"), ("strawberries", "🍓"), ("blueberries", "🫐"), ("grape", "🍇"),
        ("peach", "🍑"), ("pear", "🍐"), ("cherry", "🍒"), ("cherries", "🍒"), ("coconut", "🥥"), ("kiwi", "🥝"),
        ("melon", "🍈"), ("watermelon", "🍉"),
        ("peanut", "🥜"), ("peanut butter", "🥜"), ("almond", "🌰"), ("cashew", "🌰"), ("walnut", "🌰"),
        ("hazelnut", "🌰"), ("pecan", "🌰"), ("nuts", "🌰"), ("beans", "🫘"), ("chickpeas", "🫘"), ("lentils", "🫘"),
        ("honey", "🍯"), ("chocolate", "🍫"), ("cocoa", "🍫"), ("sugar", "🍬"), ("salt", "🧂"), ("wine", "🍷"),
        ("beer", "🍺"), ("oil", "🫗"), ("stock", "🍲"), ("broth", "🍲"), ("chicken stock", "🍲"), ("beef stock", "🍲"), ("vegetable stock", "🍲"), ("fish stock", "🍲"), ("butter beans", "🫘"), ("green beans", "🫛"), ("soy sauce", "🥢"),
    ].sorted { $0.0.count > $1.0.count }
}
