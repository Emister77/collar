import SwiftUI

/// Small red line in list rows / cards, e.g. "⚠︎ Not for your diet: Dairy (Milk), Low-Carb".
struct DietWarningBadge: View {
    let conflicts: [DietConflict]
    let missedGoals: [NutritionGoal]

    var body: some View {
        let names = conflicts.map(\.label) + missedGoals.map(\.shortTitle)
        if !names.isEmpty {
            Label("Not for your diet: " + names.joined(separator: ", "), systemImage: "exclamationmark.triangle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }
}

/// Banner on the details screen explaining exactly what doesn't fit (or that the recipe fits).
struct DietBanner: View {
    let conflicts: [DietConflict]
    let missedGoals: [NutritionGoal]
    let profileSummary: String

    private var fits: Bool { conflicts.isEmpty && missedGoals.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if fits {
                Label("Fits your diet", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                Text(profileSummary).font(.caption).foregroundStyle(.secondary)
            } else {
                Label("Doesn't fit your diet", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                ForEach(conflicts) { conflict in
                    Text("• " + conflict.text).font(.caption)
                }
                ForEach(missedGoals) { goal in
                    Text("• Misses goal: " + goal.title).font(.caption)
                }
            }
            Text("Based on ingredient names. Always check labels if you have a severe allergy.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((fits ? Color.green : Color.red).opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
