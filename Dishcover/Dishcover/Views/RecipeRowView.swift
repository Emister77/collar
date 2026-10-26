import SwiftUI

/// One row in the search results list: thumbnail, name, how well it matches the pantry,
/// and estimated macros per serving.
struct RecipeRowView: View {
    let recipe: Recipe
    let match: PantryMatch
    var macros: Macros? = nil
    var macroConfidence: MacroEstimate.Confidence = .good
    var dietConflicts: [DietConflict] = []
    var missedGoals: [NutritionGoal] = []

    var body: some View {
        HStack(spacing: 12) {
            RecipeThumbnail(url: recipe.thumbnailURL, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let subtitle = [recipe.category, recipe.area].compactMap({ $0 }).joined(separator: " · ").nilIfEmpty {
                        Text(subtitle)
                    }
                    Label(recipe.estimatedTimeText, systemImage: "timer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                ProgressView(value: match.fraction)
                    .tint(match.fraction >= 0.6 ? .green : .orange)
                Text(match.summary + (match.missing.isEmpty ? "" : " · \(match.missing.count) missing"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                MacroLine(macros: macros, confidence: macroConfidence)
                DietWarningBadge(conflicts: dietConflicts, missedGoals: missedGoals)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecipeThumbnail: View {
    let url: URL?
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.orange.opacity(0.15).overlay(Image(systemName: "fork.knife").foregroundStyle(.orange))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
