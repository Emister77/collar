import Foundation

/// Dishcover's built-in nutrition list: approximate values per 100 g (based on standard USDA
/// reference values) for the ingredients that appear in TheMealDB recipes.
///
/// Macros are calculated entirely on the device from this list, so they work offline, instantly,
/// and without any outside service or API key. Ingredients that aren't listed are left out of
/// the estimate and shown as "not in Dishcover's nutrition list" in the breakdown.
enum NutritionFacts {

    /// Returns built-in macros per 100 g for an ingredient name, or nil if it's not in the table.
    static func per100g(for ingredientName: String) -> Macros? {
        let name = normalize(ingredientName)
        for (key, macros) in sortedTable where matches(name, key) {
            return macros
        }
        return nil
    }

    /// Lowercases, translates common UK names to US ones, and drops filler words,
    /// e.g. "Plain Flour" -> "all-purpose flour", "Double Cream" -> "heavy cream".
    static func normalize(_ name: String) -> String {
        var text = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for (uk, us) in synonyms where text.contains(uk) {
            text = text.replacingOccurrences(of: uk, with: us)
        }
        let filler: Set<String> = ["fresh", "chopped", "large", "small", "medium", "free-range", "free", "range",
                                   "organic", "sliced", "diced", "minced", "boneless", "skinless", "raw",
                                   "finely", "roughly", "grated", "peeled", "whole", "extra", "virgin", "tinned", "canned"]
        return text.split(separator: " ")
            .filter { !filler.contains(String($0)) }
            .joined(separator: " ")
    }

    /// UK / TheMealDB names -> the names used in the table.
    static let synonyms: [(String, String)] = [
        ("plain flour", "all-purpose flour"), ("self-raising flour", "self-rising flour"),
        ("strong white flour", "bread flour"), ("caster sugar", "sugar"), ("granulated sugar", "sugar"),
        ("icing sugar", "powdered sugar"), ("double cream", "heavy cream"), ("whipping cream", "heavy cream"),
        ("single cream", "light cream"), ("minced beef", "ground beef"), ("beef mince", "ground beef"),
        ("lamb mince", "ground lamb"), ("pork mince", "ground pork"), ("courgette", "zucchini"),
        ("aubergine", "eggplant"), ("spring onion", "green onion"), ("scallion", "green onion"),
        ("coriander leaves", "cilantro"), ("passata", "tomato puree"), ("tomato purée", "tomato paste"),
        ("chopped tomatoes", "canned tomatoes"), ("plum tomatoes", "canned tomatoes"),
        ("king prawns", "shrimp"), ("prawns", "shrimp"), ("prawn", "shrimp"), ("rapeseed oil", "vegetable oil"),
        ("sunflower oil", "vegetable oil"), ("groundnut oil", "peanut oil"), ("bicarbonate of soda", "baking soda"),
        ("cornflour", "cornstarch"), ("chilli", "chili"), ("yoghurt", "yogurt"), ("mange tout", "snow peas"),
        ("swede", "rutabaga"), ("rocket", "arugula"), ("beef stock", "stock"), ("chicken stock", "stock"),
        ("vegetable stock", "stock"), ("fish stock", "stock"), ("broth", "stock"),
    ]

    private static func matches(_ name: String, _ key: String) -> Bool {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: key) + "(s|es)?\\b"
        return name.range(of: pattern, options: .regularExpression) != nil
    }

    /// Longest keys first, so "peanut butter" wins over "butter" and "sweet potato" over "potato".
    private static let sortedTable: [(String, Macros)] = table
        .map { ($0.0, Macros(calories: $0.1, protein: $0.2, carbs: $0.3, fat: $0.4)) }
        .sorted { $0.0.count > $1.0.count }

    // (name, kcal, protein g, carbs g, fat g) per 100 g
    private static let table: [(String, Double, Double, Double, Double)] = [
        // Meat & fish (raw)
        ("chicken breast", 120, 22.5, 0, 2.6), ("chicken thigh", 150, 18, 0, 8.5), ("chicken wing", 191, 17.5, 0, 12.8),
        ("chicken", 170, 20, 0, 10), ("ground beef", 254, 17.2, 0, 20), ("beef", 180, 20, 0, 11),
        ("steak", 180, 21, 0, 10), ("ground lamb", 282, 16.6, 0, 23.4), ("lamb", 282, 16.6, 0, 23.4),
        ("ground pork", 263, 16.9, 0, 21), ("pork", 211, 18, 0, 15), ("bacon", 417, 12.6, 1.4, 40),
        ("sausage", 300, 13, 2, 27), ("chorizo", 455, 24, 2, 38), ("ham", 145, 21, 1.5, 6), ("turkey", 148, 19.7, 0, 7.7),
        ("duck", 404, 11.5, 0, 39), ("salmon", 208, 20, 0, 13), ("tuna", 116, 26, 0, 0.8), ("cod", 82, 18, 0, 0.7),
        ("haddock", 74, 16, 0, 0.5), ("white fish", 82, 18, 0, 0.7), ("fish", 100, 19, 0, 2.5),
        ("shrimp", 85, 20, 0, 0.5), ("mussels", 86, 12, 3.7, 2.2), ("squid", 92, 15.6, 3.1, 1.4),
        ("anchovy", 210, 29, 0, 9.7), ("smoked salmon", 117, 18, 0, 4.3), ("trout", 141, 20, 0, 6.2),
        ("mackerel", 205, 18.6, 0, 13.9), ("sardines", 208, 24.6, 0, 11.5), ("tilapia", 96, 20, 0, 1.7),
        ("sea bass", 97, 18.4, 0, 2), ("halibut", 91, 18.6, 0, 1.3), ("monkfish", 76, 14.5, 0, 1.5),
        ("crab", 87, 18, 0, 1.1), ("lobster", 77, 16.5, 0, 0.8), ("scallops", 69, 12, 3.2, 0.5),
        ("clams", 72, 12.8, 2.6, 1), ("octopus", 82, 14.9, 2.2, 1), ("salami", 380, 22, 1.5, 31),
        ("pepperoni", 504, 19, 1, 46), ("prosciutto", 250, 26, 0, 15), ("pancetta", 400, 13, 1, 39),
        ("venison", 120, 23, 0, 2.4), ("goat", 109, 20.6, 0, 2.3), ("veal", 144, 19, 0, 7), ("liver", 135, 20, 3.9, 3.6),
        ("lard", 902, 0, 0, 100), ("suet", 854, 1.5, 0, 94),
        ("egg yolk", 322, 15.9, 3.6, 26.5), ("egg white", 52, 10.9, 0.7, 0.2),
        ("egg", 143, 12.6, 0.7, 9.5), ("tofu", 76, 8, 1.9, 4.8), ("tempeh", 192, 20, 7.6, 10.8),
        // Dairy
        ("peanut butter", 588, 25, 20, 50), ("butter", 717, 0.9, 0.1, 81), ("coconut milk", 230, 2.3, 6, 24),
        ("coconut cream", 330, 3.6, 6.7, 34.7), ("condensed milk", 321, 7.9, 54.4, 8.7), ("milk", 61, 3.2, 4.8, 3.3),
        ("heavy cream", 340, 2.8, 2.7, 36), ("light cream", 195, 2.7, 4, 19), ("sour cream", 198, 2.4, 4.6, 19.4),
        ("creme fraiche", 293, 2.4, 2.8, 30), ("crème fraîche", 293, 2.4, 2.8, 30), ("cream cheese", 342, 6, 4.1, 34),
        ("cream", 340, 2.8, 2.7, 36), ("parmesan", 431, 38, 4.1, 29), ("mozzarella", 280, 28, 3.1, 17),
        ("feta", 264, 14, 4.1, 21), ("ricotta", 174, 11.3, 3, 13), ("mascarpone", 429, 4.6, 4.8, 44),
        ("cheddar", 403, 25, 1.3, 33), ("cheese", 380, 24, 2, 31), ("greek yogurt", 97, 9, 3.9, 5),
        ("yogurt", 61, 3.5, 4.7, 3.3), ("ghee", 876, 0.3, 0, 99.5), ("buttermilk", 40, 3.3, 4.8, 0.9),
        ("evaporated milk", 134, 6.8, 10, 7.6), ("goat cheese", 364, 22, 2.5, 30), ("halloumi", 321, 21, 2.6, 25),
        ("paneer", 296, 20, 3.6, 22), ("brie", 334, 20.8, 0.5, 27.7), ("gruyere", 413, 30, 0.4, 32), ("gruyère", 413, 30, 0.4, 32), ("goats cheese", 364, 22, 2.5, 30),
        ("blue cheese", 353, 21, 2.3, 28.7), ("cottage cheese", 98, 11, 3.4, 4.3), ("margarine", 717, 0.2, 0.7, 80),
        ("ice cream", 207, 3.5, 24, 11), ("custard", 122, 3.5, 18, 4),
        // Grains, flours, bread, pasta (dry)
        ("self-rising flour", 354, 9.9, 74, 1), ("bread flour", 361, 12, 72.5, 1.7), ("rice flour", 366, 6, 80, 1.4),
        ("cornstarch", 381, 0.3, 91, 0.1), ("flour", 364, 10.3, 76, 1), ("rice noodles", 364, 6, 80, 0.6),
        ("egg noodles", 384, 14, 71, 4.4), ("noodles", 371, 13, 75, 1.5), ("brown rice", 370, 7.5, 77, 2.7),
        ("cooked rice", 130, 2.7, 28, 0.3), ("cooked pasta", 158, 5.8, 31, 0.9), ("rice", 365, 7.1, 80, 0.7), ("spaghetti", 371, 13, 75, 1.5), ("lasagne sheets", 371, 13, 75, 1.5),
        ("pasta", 371, 13, 75, 1.5), ("penne", 371, 13, 75, 1.5), ("macaroni", 371, 13, 75, 1.5),
        ("breadcrumbs", 395, 13.4, 72, 5.3), ("bread", 265, 9, 49, 3.2), ("oats", 389, 16.9, 66, 6.9),
        ("couscous", 376, 12.8, 77, 0.6), ("tortilla", 310, 8.3, 52, 7.7), ("puff pastry", 558, 7.4, 45.7, 38.5),
        ("pastry", 527, 6.5, 53, 32), ("pita", 275, 9, 56, 1.2), ("pitta", 275, 9, 56, 1.2), ("sourdough", 274, 11, 51, 1.8), ("brioche", 360, 8, 48, 15), ("naan", 291, 9.6, 50, 5.7),
        ("quinoa", 368, 14, 64, 6), ("bulgur", 342, 12, 76, 1.3), ("polenta", 370, 8, 79, 3.6),
        ("cornmeal", 370, 8, 79, 3.6), ("semolina", 360, 12.7, 73, 1), ("buckwheat", 343, 13, 72, 3.4),
        ("barley", 352, 9.9, 78, 1.2), ("split peas", 341, 24.5, 60, 1.2), ("tortilla chips", 489, 7, 63, 23),
        ("digestive biscuits", 471, 7, 66, 20), ("biscuits", 471, 7, 66, 20), ("crackers", 430, 9, 70, 12),
        ("cornflakes", 357, 7.5, 84, 0.4), ("granola", 471, 10, 64, 20), ("rice paper", 330, 6, 80, 0.5),
        // Sugar & sweet
        ("brown sugar", 380, 0.1, 98, 0), ("powdered sugar", 389, 0, 100, 0), ("sugar", 387, 0, 100, 0),
        ("honey", 304, 0.3, 82.4, 0), ("maple syrup", 260, 0, 67, 0.1), ("golden syrup", 325, 0, 81, 0),
        ("dark chocolate", 546, 4.9, 61, 31), ("chocolate", 535, 7.7, 59, 30), ("cocoa", 228, 19.6, 58, 13.7),
        ("vanilla", 288, 0.1, 12.7, 0.1), ("jam", 278, 0.4, 69, 0.1), ("nutella", 539, 6.3, 57.5, 31),
        ("molasses", 290, 0, 75, 0.1), ("treacle", 290, 0, 75, 0.1), ("marzipan", 444, 9, 50, 24),
        ("desiccated coconut", 660, 6.9, 24, 65), ("coconut", 354, 3.3, 15, 33),
        // Oils
        ("olive oil", 884, 0, 0, 100), ("vegetable oil", 884, 0, 0, 100), ("sesame oil", 884, 0, 0, 100),
        ("coconut oil", 892, 0, 0, 99), ("peanut oil", 884, 0, 0, 100), ("oil", 884, 0, 0, 100),
        // Vegetables & fruit (raw)
        ("red onion", 40, 1.1, 9.3, 0.1), ("green onion", 32, 1.8, 7.3, 0.2), ("shallot", 72, 2.5, 16.8, 0.1),
        ("onion", 40, 1.1, 9.3, 0.1), ("garlic", 149, 6.4, 33, 0.5), ("ginger", 80, 1.8, 18, 0.8),
        ("tomato paste", 82, 4.3, 18.9, 0.5), ("tomato puree", 38, 1.7, 9, 0.2), ("canned tomatoes", 24, 1.2, 4, 0.3),
        ("cherry tomato", 18, 0.9, 3.9, 0.2), ("tomato", 18, 0.9, 3.9, 0.2), ("sweet potato", 86, 1.6, 20, 0.1),
        ("potato", 77, 2, 17, 0.1), ("carrot", 41, 0.9, 9.6, 0.2), ("celery", 16, 0.7, 3, 0.2),
        ("bell pepper", 31, 1, 6, 0.3), ("red pepper", 31, 1, 6, 0.3), ("green pepper", 20, 0.9, 4.6, 0.2),
        ("chili", 40, 1.9, 8.8, 0.4), ("mushroom", 22, 3.1, 3.3, 0.3), ("spinach", 23, 2.9, 3.6, 0.4),
        ("broccoli", 34, 2.8, 6.6, 0.4), ("cauliflower", 25, 1.9, 5, 0.3), ("cabbage", 25, 1.3, 5.8, 0.1),
        ("zucchini", 17, 1.2, 3.1, 0.3), ("eggplant", 25, 1, 5.9, 0.2), ("peas", 81, 5.4, 14.5, 0.4),
        ("snow peas", 42, 2.8, 7.6, 0.2), ("green beans", 31, 1.8, 7, 0.2), ("sweetcorn", 86, 3.3, 19, 1.4),
        ("corn", 86, 3.3, 19, 1.4), ("lettuce", 15, 1.4, 2.9, 0.2), ("cucumber", 15, 0.7, 3.6, 0.1),
        ("avocado", 160, 2, 8.5, 14.7), ("leek", 61, 1.5, 14, 0.3), ("lemon juice", 22, 0.4, 6.9, 0.2),
        ("lime juice", 25, 0.4, 8.4, 0.1), ("lemon", 29, 1.1, 9.3, 0.3), ("lime", 30, 0.7, 10.5, 0.2),
        ("apple", 52, 0.3, 14, 0.2), ("banana", 89, 1.1, 23, 0.3), ("raisins", 299, 3.1, 79, 0.5), ("sultanas", 299, 3.1, 79, 0.5), ("apricot", 48, 1.4, 11, 0.4), ("gherkin", 12, 0.3, 2.4, 0.2), ("pickle", 12, 0.3, 2.4, 0.2),
        ("cilantro", 23, 2.1, 3.7, 0.5), ("parsley", 36, 3, 6.3, 0.8), ("basil", 23, 3.2, 2.7, 0.6),
        ("mint", 70, 3.8, 15, 0.9), ("dill", 43, 3.5, 7, 1.1), ("thyme", 101, 5.6, 24, 1.7), ("rosemary", 131, 3.3, 21, 5.9),
        ("sage", 315, 10.6, 61, 12.8), ("bay leaf", 313, 7.6, 75, 8.4), ("bay leaves", 313, 7.6, 75, 8.4), ("coriander", 23, 2.1, 3.7, 0.5), ("chives", 30, 3.3, 4.4, 0.7),
        ("orange juice", 45, 0.7, 10.4, 0.2), ("orange", 47, 0.9, 12, 0.1), ("blueberries", 57, 0.7, 14.5, 0.3),
        ("strawberries", 32, 0.7, 7.7, 0.3), ("raspberries", 52, 1.2, 12, 0.7), ("pineapple", 50, 0.5, 13, 0.1),
        ("mango", 60, 0.8, 15, 0.4), ("pear", 57, 0.4, 15, 0.1), ("peach", 39, 0.9, 9.5, 0.3),
        ("dates", 282, 2.5, 75, 0.4), ("dried apricots", 241, 3.4, 63, 0.5), ("cranberries", 308, 0.1, 82, 1.4),
        ("olives", 115, 0.8, 6, 10.7), ("capers", 23, 2.4, 4.9, 0.9), ("jalapeno", 29, 0.9, 6.5, 0.4),
        ("beetroot", 43, 1.6, 9.6, 0.2), ("asparagus", 20, 2.2, 3.9, 0.1), ("kale", 49, 4.3, 8.8, 0.9),
        ("bok choy", 13, 1.5, 2.2, 0.2), ("pak choi", 13, 1.5, 2.2, 0.2), ("bean sprouts", 30, 3, 5.9, 0.2),
        ("beansprouts", 30, 3, 5.9, 0.2), ("bamboo shoots", 27, 2.6, 5.2, 0.3), ("water chestnut", 97, 1.4, 24, 0.1),
        ("butternut squash", 45, 1, 11.7, 0.1), ("pumpkin", 26, 1, 6.5, 0.1), ("parsnip", 75, 1.2, 18, 0.3),
        ("turnip", 28, 0.9, 6.4, 0.1), ("rutabaga", 37, 1.1, 8.6, 0.2), ("fennel", 31, 1.2, 7.3, 0.2),
        ("artichoke", 47, 3.3, 10.5, 0.2), ("okra", 33, 1.9, 7.5, 0.2), ("plantain", 122, 1.3, 32, 0.4),
        ("yam", 118, 1.5, 28, 0.2), ("cassava", 160, 1.4, 38, 0.3), ("arugula", 25, 2.6, 3.7, 0.7),
        ("watercress", 11, 2.3, 1.3, 0.1), ("mixed vegetables", 40, 2, 7, 0.3), ("vegetable", 40, 2, 7, 0.3), ("radish", 16, 0.7, 3.4, 0.1), ("celeriac", 42, 1.5, 9.2, 0.3),
        // Beans, lentils, nuts, seeds
        ("chickpeas", 139, 7, 22.5, 2.6), ("kidney beans", 84, 5.2, 15.5, 0.3), ("black beans", 91, 6, 16.5, 0.3),
        ("lentils", 352, 24.6, 63, 1.1), ("peanuts", 567, 25.8, 16, 49), ("almonds", 579, 21, 22, 50),
        ("cashew", 553, 18, 30, 44), ("walnuts", 654, 15, 14, 65), ("pine nuts", 673, 13.7, 13, 68),
        ("sesame seed", 573, 17.7, 23, 50), ("tahini", 595, 17, 21, 54), ("pecans", 691, 9, 14, 72),
        ("hazelnuts", 628, 15, 17, 61), ("pistachios", 560, 20, 28, 45), ("pumpkin seeds", 559, 30, 11, 49),
        ("sunflower seeds", 584, 21, 20, 51), ("flaxseed", 534, 18, 29, 42), ("chia seeds", 486, 17, 42, 31),
        ("butter beans", 79, 4.8, 15, 0.2), ("cannellini beans", 91, 6, 16, 0.3), ("white beans", 91, 6, 16, 0.3),
        ("pinto beans", 86, 4.9, 15, 0.7), ("black-eyed peas", 77, 4.7, 14, 0.5), ("edamame", 121, 11.9, 8.9, 5.2),
        ("hummus", 166, 7.9, 14.3, 9.6),
        // Sauces, stock, drinks
        ("soy sauce", 53, 8.1, 4.9, 0.6), ("fish sauce", 35, 5, 3.6, 0), ("oyster sauce", 51, 1.4, 11, 0.3),
        ("hoisin", 220, 3.3, 44, 3.4), ("worcestershire", 78, 0, 19.5, 0), ("mayonnaise", 680, 1, 0.6, 75),
        ("ketchup", 101, 1, 27, 0.1), ("mustard", 66, 4.4, 5.8, 4), ("balsamic vinegar", 88, 0.5, 17, 0),
        ("vinegar", 18, 0, 0, 0), ("stock cube", 250, 10, 20, 15), ("stock", 10, 1, 1, 0.4),
        ("red wine", 85, 0.1, 2.6, 0), ("white wine", 82, 0.1, 2.6, 0), ("wine", 85, 0.1, 2.6, 0), ("beer", 43, 0.5, 3.6, 0),
        ("sriracha", 93, 1.9, 19, 0.9), ("hot sauce", 11, 0.5, 1.8, 0.4), ("bbq sauce", 172, 0.8, 41, 0.6),
        ("barbecue sauce", 172, 0.8, 41, 0.6), ("sweet chili sauce", 220, 0.5, 54, 0.2), ("pesto", 430, 5, 6, 44),
        ("salsa", 36, 1.5, 7, 0.2), ("curry paste", 130, 2, 15, 6), ("miso", 199, 12, 26, 6),
        ("tamarind", 239, 2.8, 62, 0.6), ("teriyaki", 89, 5.9, 15.6, 0), ("mirin", 241, 0.2, 43, 0),
        ("sake", 134, 0.5, 5, 0), ("rum", 231, 0, 0, 0), ("brandy", 231, 0, 0, 0), ("vodka", 231, 0, 0, 0),
        ("sherry", 140, 0.2, 8, 0), ("cider", 49, 0, 5.9, 0), ("coffee", 1, 0.1, 0, 0),
        ("gelatine", 335, 86, 0, 0), ("gelatin", 335, 86, 0, 0), ("baking powder", 53, 0, 28, 0), ("baking soda", 0, 0, 0, 0), ("yeast", 325, 40, 41, 7.6),
        // Dried spices (small amounts, so a shared average is close enough)
        ("paprika", 282, 14, 54, 13), ("cumin", 375, 18, 44, 22), ("turmeric", 312, 9.7, 67, 3.3),
        ("cinnamon", 247, 4, 81, 1.2), ("curry powder", 325, 14, 56, 14), ("garam masala", 379, 15, 45, 15),
        ("chili powder", 282, 13.5, 50, 14), ("oregano", 265, 9, 69, 4.3), ("ground coriander", 298, 12.4, 55, 17.8),
        ("nutmeg", 525, 5.8, 49, 36), ("cardamom", 311, 11, 68, 6.7), ("cloves", 274, 6, 66, 13),
        ("cayenne", 318, 12, 57, 17), ("mixed spice", 263, 6, 72, 8.7), ("allspice", 263, 6, 72, 8.7),
        ("star anise", 337, 17.6, 50, 16), ("saffron", 310, 11, 65, 6), ("seasoning", 300, 12, 50, 10),
        ("fennel seed", 345, 15.8, 52, 14.9), ("mustard seed", 508, 26, 28, 36),
        // West African staples
        ("egusi", 557, 28, 15, 47), ("scotch bonnet", 40, 1.9, 8.8, 0.4), ("stockfish", 290, 63, 0, 2.4),
        ("crayfish", 300, 60, 0, 5), ("palm oil", 884, 0, 0, 100), ("ogbono", 650, 8, 15, 63),
        ("black eyed beans", 77, 4.7, 14, 0.5), ("garri", 360, 1.2, 88, 0.5), ("fufu", 267, 1.7, 63, 0.3),
    ]
}
