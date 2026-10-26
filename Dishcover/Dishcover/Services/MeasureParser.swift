import Foundation

/// Turns TheMealDB measures like "2 cups", "175g/6oz", "2 x 400g tins", "juice of 1" or
/// "3 large" into grams, so the per-100 g nutrition values can be scaled. All conversions are
/// approximate.
enum MeasureParser {

    struct Amount: Equatable {
        let grams: Double
        /// true when the measure was blank and a typical amount was used instead.
        let assumed: Bool
    }

    /// Grams for one ingredient line.
    /// - `grams == 0` means negligible (salt, water, "to taste", "garnish").
    /// - `nil` means the measure couldn't be understood, so the ingredient is left out.
    static func amount(for ingredient: Ingredient) -> Amount? {
        amount(name: ingredient.name.lowercased(), measure: ingredient.measure)
    }

    private static func amount(name: String, measure: String) -> Amount? {
        if negligibleIngredients.contains(where: { name == $0 || name.hasPrefix($0 + " ") }) { return exact(0) }

        var text = " " + measure.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for (symbol, replacement) in unicodeFractions {
            text = text.replacingOccurrences(of: symbol, with: replacement)
        }
        text = text.trimmingCharacters(in: .whitespaces)
        // Remember a bracketed amount like "1 (12 oz.)" before removing brackets.
        var bracketed: String?
        if let open = text.firstIndex(of: "("), let close = text[open...].firstIndex(of: ")") {
            bracketed = String(text[text.index(after: open)..<close])
        }
        // "(6oz)" and "175g/6oz" -> keep only the first unit
        text = text.replacingOccurrences(of: #"\([^)]*\)"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"(\d+(?:\.\d+)?\s*[a-z]+)\s*/\s*[\d\s./]+\s*[a-z]+"#,
                                         with: "$1", options: .regularExpression)
        // "400g" -> "400 g"
        text = text.replacingOccurrences(of: #"(\d)([a-z])"#, with: "$1 $2", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespaces)

        // Blank measure: count whole items, or use a typical amount for staples like oil.
        if text.isEmpty {
            if let piece = knownPieceWeight(for: name) { return exact(piece) }
            if let typical = typicalAmount(for: name) { return Amount(grams: typical, assumed: true) }
            return nil
        }

        if negligibleMeasures.contains(where: { text.contains($0) }) { return exact(0) }
        if text.contains("pinch") || text.contains("dash") { return exact(0.5) }
        for (phrase, grams) in phraseAmounts where text.contains(phrase) { return exact(grams) }

        // "2 x 400g tins" -> 2 × (400 g)
        if let match = text.range(of: #"^\d+(\.\d+)?\s*x\s*(?=\d)"#, options: .regularExpression) {
            let multiplier = Double(text[match].filter { $0.isNumber || $0 == "." }) ?? 1
            let rest = String(text[match.upperBound...])
            guard let inner = amount(name: name, measure: rest) else { return nil }
            return Amount(grams: inner.grams * multiplier, assumed: inner.assumed)
        }

        // Pull out the quantity ("1 1/2", "2-3" -> 2, "a", "half", "few") and the words after it.
        var quantity: Double?
        var words: [String] = []
        for raw in text.split(whereSeparator: { $0 == " " || $0 == "-" }) {
            let token = String(raw).trimmingCharacters(in: .punctuationCharacters)   // keeps "1/2" and "1.5" intact
            if token.isEmpty || fillerWords.contains(token) { continue }
            if words.isEmpty, let word = wordNumbers[token] {
                quantity = (quantity ?? 1) * word
                continue
            }
            if words.isEmpty, let number = number(from: token) {
                if let current = quantity {
                    if token.contains("/") { quantity = current + number }   // "1 1/2"
                    // otherwise it's the second number of a range like "2-3": ignore it
                } else {
                    quantity = number
                }
                continue
            }
            words.append(token)
        }

        let count = quantity ?? 1
        let unit = words.first ?? ""

        // "juice of 1 lemon" / "zest of 2": the number can come after the words
        if words.contains("juice") || words.contains("zest") {
            let pieces = quantity ?? words.compactMap(number(from:)).first ?? 1
            return exact(pieces * (words.contains("juice") ? 30 : 2))
        }

        if let grams = weightUnits[unit] { return exact(count * grams) }
        if unit == "fl" { return exact(count * 30 * density(for: name)) }   // "fl oz"
        if let ml = volumeUnits[unit] { return exact(count * ml * density(for: name)) }
        if let grams = containerUnits[unit] {
            // a packet of yeast or gelatine is tiny compared with a packet of pasta
            if name.contains("yeast") { return exact(count * 7) }
            if name.contains("gelatin") { return exact(count * 10) }
            return exact(count * grams)
        }
        if let grams = pieceUnit(unit, name: name) { return exact(count * grams) }
        if let size = sizeWords[unit] { return exact(count * pieceWeight(for: name) * size) }
        if quantity != nil {
            // "1 (12 oz.)" -> 1 × 12 oz
            if unit.isEmpty, let bracketed, let inner = amount(name: name, measure: bracketed), inner.grams > 0 {
                return exact(count * inner.grams)
            }
            return exact(count * pieceWeight(for: name))   // "3" (potatoes)
        }
        return nil
    }

    private static func exact(_ grams: Double) -> Amount { Amount(grams: grams, assumed: false) }

    // MARK: - Tables

    private static let negligibleIngredients = ["water", "salt", "ice", "black pepper", "pepper", "sea salt",
                                                "white pepper", "ground black pepper", "kosher salt", "cold water",
                                                "hot water", "boiling water"]
    private static let negligibleMeasures = ["to taste", "to serve", "garnish", "sprinkl", "as needed", "as required",
                                             "optional", "season"]
    private static let phraseAmounts: [(String, Double)] = [
        ("drizzle", 10), ("for frying", 15), ("to fry", 15), ("for greasing", 5), ("to grease", 5),
        ("for dusting", 5), ("to dust", 5), ("to glaze", 10), ("splash", 15), ("glug", 15),
    ]
    private static let unicodeFractions = ["½": " 1/2", "¼": " 1/4", "¾": " 3/4", "⅓": " 1/3", "⅔": " 2/3", "⅛": " 1/8"]
    private static let fillerWords: Set<String> = ["heaped", "heaping", "level", "rounded", "generous", "good", "scant",
                                                   "about", "approx", "approximately", "of", "fresh", "chopped", "sliced",
                                                   "diced", "minced", "grated", "finely", "roughly", "plus", "extra",
                                                   "cut", "into", "thinly", "thick", "thin", "or", "and", "to"]
    private static let wordNumbers: [String: Double] = ["a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4,
                                                        "half": 0.5, "couple": 2, "few": 3, "several": 4]

    private static let weightUnits: [String: Double] = [
        "g": 1, "gram": 1, "grams": 1, "gr": 1, "kg": 1000, "kilo": 1000, "kilos": 1000,
        "oz": 28.35, "ounce": 28.35, "ounces": 28.35, "lb": 453.6, "lbs": 453.6, "pound": 453.6, "pounds": 453.6,
    ]

    /// Millilitres per unit.
    private static let volumeUnits: [String: Double] = [
        "ml": 1, "l": 1000, "litre": 1000, "liter": 1000, "litres": 1000, "liters": 1000, "cl": 10, "dl": 100,
        "tsp": 5, "tsps": 5, "teaspoon": 5, "teaspoons": 5, "t": 5,
        "tbsp": 15, "tbsps": 15, "tbs": 15, "tblsp": 15, "tbls": 15, "tablespoon": 15, "tablespoons": 15, "tb": 15,
        "cup": 240, "cups": 240, "c": 240, "pint": 473, "pints": 473, "quart": 946,
        "glass": 150, "mug": 250, "bottle": 330, "shot": 30,
    ]

    /// Grams for packaged amounts.
    private static let containerUnits: [String: Double] = [
        "can": 400, "cans": 400, "tin": 400, "tins": 400, "pack": 250, "packs": 250, "packet": 250, "packets": 250,
        "package": 250, "bag": 200, "bags": 200, "jar": 350, "jars": 350, "pot": 150, "pots": 150, "carton": 250,
        "sachet": 7, "sachets": 7, "cube": 10, "cubes": 10, "block": 250,
    ]

    /// Grams for one "piece"-style unit; some depend on the ingredient ("stick" of butter vs celery).
    private static func pieceUnit(_ unit: String, name: String) -> Double? {
        switch unit {
        case "clove", "cloves": return 5
        case "slice", "slices": return name.contains("bacon") ? 25 : 30
        case "rasher", "rashers", "strip", "strips": return 25
        case "handful", "handfuls": return 30
        case "bunch", "bunches": return 50
        case "sprig", "sprigs": return 1
        case "knob": return 15
        case "leaf", "leaves": return 0.5
        case "stick", "sticks":
            if name.contains("celery") { return 40 }
            if name.contains("cinnamon") { return 3 }
            return 113   // stick of butter
        case "stalk", "stalks": return 40
        case "head", "heads": return name.contains("garlic") ? 40 : 300
        case "ear", "ears", "cob", "cobs": return 100
        case "fillet", "fillets": return 150
        case "breast", "breasts": return 170
        case "thigh", "thighs": return 110
        case "drumstick", "drumsticks": return 100
        case "leg", "legs": return 200
        case "wedge", "wedges": return 15
        case "inch", "inches": return 10        // ginger, "2 inch piece"
        case "cm": return 4
        case "piece", "pieces", "whole", "item", "items": return pieceWeight(for: name)
        default: return nil
        }
    }

    private static let sizeWords: [String: Double] = ["large": 1.25, "big": 1.25, "medium": 1, "small": 0.75]

    /// Approximate grams per millilitre (water = 1).
    private static func density(for name: String) -> Double {
        let table: [(String, Double)] = [
            ("icing sugar", 0.5), ("brown sugar", 0.9), ("flour", 0.53), ("sugar", 0.85), ("butter", 0.96),
            ("oil", 0.92), ("milk", 1.03), ("rice", 0.85), ("oats", 0.4), ("honey", 1.42), ("syrup", 1.33),
            ("cheese", 0.4), ("breadcrumbs", 0.45), ("cocoa", 0.42), ("nuts", 0.6), ("almonds", 0.6),
            ("lentils", 0.8), ("couscous", 0.75), ("quinoa", 0.75), ("peas", 0.6), ("spinach", 0.12),
            ("herbs", 0.1), ("parsley", 0.1), ("coriander", 0.1), ("cilantro", 0.1), ("basil", 0.1),
        ]
        return table.first { name.contains($0.0) }?.1 ?? 1.0
    }

    /// Grams for one whole item (100 g if unknown).
    private static func pieceWeight(for name: String) -> Double {
        knownPieceWeight(for: name) ?? 100
    }

    private static func knownPieceWeight(for name: String) -> Double? {
        pieceWeights.first { name.contains($0.0) }?.1
    }

    /// Longest names first, so "sweet potato" is checked before "potato".
    private static let pieceWeights: [(String, Double)] = [
        ("egg yolk", 17), ("egg white", 33), ("egg", 50), ("garlic", 5), ("red onion", 110), ("spring onion", 15),
        ("green onion", 15), ("onion", 110), ("shallot", 30), ("cherry tomato", 15), ("tomato", 120),
        ("sweet potato", 130), ("potato", 170), ("lemon", 60), ("lime", 45), ("orange", 130),
        ("chicken breast", 170), ("chicken thigh", 110), ("chicken leg", 200), ("drumstick", 100),
        ("carrot", 60), ("celery", 40), ("bell pepper", 120), ("red pepper", 120), ("green pepper", 120),
        ("yellow pepper", 120), ("jalapeno", 14), ("chilli", 15), ("chili", 15), ("cucumber", 300), ("leek", 90),
        ("mushroom", 18), ("apple", 180), ("pear", 180), ("banana", 120), ("avocado", 150), ("mango", 200),
        ("courgette", 200), ("zucchini", 200), ("aubergine", 300), ("eggplant", 300), ("sausage", 65),
        ("bacon", 25), ("tortilla", 45), ("pitta", 60), ("pita", 60), ("bun", 60), ("bread", 30), ("naan", 90),
        ("bay lea", 0.2), ("cardamom", 0.2), ("star anise", 0.5), ("lettuce", 300), ("cabbage", 900),
        ("cauliflower", 600), ("broccoli", 300), ("pineapple", 900), ("stock cube", 10),
    ].sorted { $0.0.count > $1.0.count }

    /// Typical amount when the measure is blank, for staples recipes often leave unmeasured.
    private static func typicalAmount(for name: String) -> Double? {
        let table: [(String, Double)] = [
            ("oil", 15), ("butter", 15), ("soy sauce", 15), ("fish sauce", 10), ("vinegar", 15),
            ("worcestershire", 5), ("stock", 250), ("milk", 100), ("cream", 50), ("cheese", 30), ("sugar", 10),
            ("honey", 15), ("flour", 15), ("parsley", 5), ("coriander", 5), ("cilantro", 5), ("basil", 5),
            ("mint", 5), ("thyme", 2), ("oregano", 2), ("paprika", 2), ("cumin", 2), ("chili powder", 2),
            ("cinnamon", 2), ("turmeric", 2), ("ginger", 10), ("lemon juice", 15), ("lime juice", 15),
        ]
        return table.first { name.contains($0.0) }?.1
    }

    private static func number(from token: String) -> Double? {
        if let value = Double(token) { return value }
        let parts = token.split(separator: "/")
        if parts.count == 2, let top = Double(parts[0]), let bottom = Double(parts[1]), bottom != 0 {
            return top / bottom
        }
        return nil
    }
}
