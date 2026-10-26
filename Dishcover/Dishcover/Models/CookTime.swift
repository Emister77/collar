import Foundation

/// Cook-time ranges the user can filter by.
enum CookTimeRange: String, CaseIterable, Identifiable {
    case any = "Any"
    case under15 = "< 15 min"
    case from15to30 = "15–30 min"
    case from30to60 = "30–60 min"
    case over60 = "60+ min"

    var id: String { rawValue }

    func contains(_ minutes: Int) -> Bool {
        switch self {
        case .any: return true
        case .under15: return minutes < 15
        case .from15to30: return minutes >= 15 && minutes <= 30
        case .from30to60: return minutes > 30 && minutes <= 60
        case .over60: return minutes > 60
        }
    }
}

extension Recipe {
    /// Estimated total time in minutes (prep + cooking).
    ///
    /// TheMealDB has no cooking-time field, so the estimate is built from the recipe itself:
    /// - **Cooking:** every time written in the instructions is added up
    ///   ("bake for 35 minutes", "simmer 1 hour", "fry 3-4 mins" → upper end of a range).
    ///   If the instructions mention no times, each step counts as 5 minutes.
    /// - **Prep:** about 2 minutes per ingredient (at least 5 minutes) for measuring and chopping.
    var estimatedMinutes: Int {
        let prep = max(5, ingredients.count * 2)
        let written = Recipe.minutesMentioned(in: instructions)
        let cooking = written > 0 ? written : steps.count * 5
        return prep + cooking
    }

    /// e.g. "~35 min" or "~1 hr 20 min"
    var estimatedTimeText: String {
        let m = estimatedMinutes
        if m < 60 { return "~\(m) min" }
        let hours = m / 60, rest = m % 60
        return rest == 0 ? "~\(hours) hr" : "~\(hours) hr \(rest) min"
    }

    /// Adds up every duration written in a block of text.
    static func minutesMentioned(in text: String) -> Int {
        var total = 0.0
        let lower = text.lowercased()
            .replacingOccurrences(of: "half an hour", with: "30 minutes")
            .replacingOccurrences(of: "an hour", with: "1 hour")
            .replacingOccurrences(of: "overnight", with: "8 hours")

        // number, optional range ("3-4", "3 to 4"), then a time unit
        let pattern = #"(\d+(?:\.\d+)?)(?:\s*(?:-|–|to)\s*(\d+(?:\.\d+)?))?\s*(hours?|hrs?|minutes?|mins?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(lower.startIndex..., in: lower)

        for match in regex.matches(in: lower, range: range) {
            func group(_ i: Int) -> String? {
                guard let r = Range(match.range(at: i), in: lower) else { return nil }
                return String(lower[r])
            }
            let low = Double(group(1) ?? "") ?? 0
            let value = Double(group(2) ?? "") ?? low   // use the upper end of a range
            let unit = group(3) ?? ""
            total += unit.hasPrefix("h") ? value * 60 : value
        }
        return Int(total.rounded())
    }
}
