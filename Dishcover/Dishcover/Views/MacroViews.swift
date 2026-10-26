import SwiftUI

/// One-line macro summary used in list rows and the random-recipe card.
struct MacroLine: View {
    let macros: Macros?
    var confidence: MacroEstimate.Confidence = .good

    var body: some View {
        if let macros {
            HStack(spacing: 8) {
                Label("\(confidence == .rough ? "~" : "")\(Int(macros.calories.rounded())) kcal", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                Text("P \(Int(macros.protein.rounded()))g")
                Text("C \(Int(macros.carbs.rounded()))g")
                Text("F \(Int(macros.fat.rounded()))g")
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .accessibilityLabel("Per serving: " + macros.shortText)
        }
    }
}

/// Four tiles (calories, protein, carbs, fat), a servings stepper, how reliable the estimate is,
/// and a button to see how each ingredient was counted. Used on the details screen.
struct MacroPanel: View {
    let estimate: MacroEstimate
    @Binding var servings: Int
    @State private var showingBreakdown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Nutrition per serving").font(.headline)
                Spacer()
                Stepper("\(servings) serving\(servings == 1 ? "" : "s")", value: $servings, in: 1...12)
                    .font(.subheadline)
                    .fixedSize()
            }

            if estimate.hasData {
                let m = estimate.perServing(servings)
                HStack(spacing: 8) {
                    tile("Calories", "\(Int(m.calories.rounded()))", "kcal", .orange)
                    tile("Protein", "\(Int(m.protein.rounded()))", "g", .blue)
                    tile("Carbs", "\(Int(m.carbs.rounded()))", "g", .green)
                    tile("Fat", "\(Int(m.fat.rounded()))", "g", .pink)
                }
                HStack(spacing: 6) {
                    ConfidenceTag(confidence: estimate.confidence, label: estimate.confidenceLabel)
                    Text(estimate.coverageText).font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button("See breakdown") { showingBreakdown = true }
                        .font(.caption.weight(.semibold))
                }
            } else {
                Text("None of this recipe's ingredients could be measured, so macros aren't available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("See why") { showingBreakdown = true }.font(.caption.weight(.semibold))
            }
        }
        .sheet(isPresented: $showingBreakdown) {
            NutritionBreakdownView(estimate: estimate, servings: servings)
        }
    }

    private func tile(_ title: String, _ value: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value).font(.title3.bold())
                Text(unit).font(.caption2)
            }
            .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ConfidenceTag: View {
    let confidence: MacroEstimate.Confidence
    let label: String

    private var color: Color {
        switch confidence {
        case .good: return .green
        case .fair: return .orange
        case .rough: return .red
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
    }
}

/// Sheet listing every ingredient: its amount in grams, its calories, and whether it was counted.
struct NutritionBreakdownView: View {
    let estimate: MacroEstimate
    let servings: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let m = estimate.perServing(servings)
                    LabeledContent("Per serving (\(servings))", value: m.shortText)
                        .font(.subheadline)
                    LabeledContent("Whole recipe", value: "\(Int(estimate.total.calories.rounded())) kcal")
                        .font(.subheadline)
                } footer: {
                    Text("Calculated on your device from each ingredient's amount and Dishcover's built-in "
                         + "nutrition list. Values are estimates.")
                }

                Section("Ingredients") {
                    ForEach(estimate.items) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Image(systemName: item.isCounted ? "checkmark.circle.fill" : "questionmark.circle")
                                    .foregroundStyle(item.isCounted ? .green : .orange)
                                Text(item.name).font(.subheadline.weight(.medium))
                                Spacer()
                                if let macros = item.macros, macros.calories > 0 {
                                    Text("\(Int(macros.calories.rounded())) kcal").font(.subheadline)
                                }
                            }
                            HStack {
                                Text(item.measure.isEmpty ? "No amount listed" : item.measure)
                                if let grams = item.grams, grams > 0 {
                                    Text("≈ \(Int(grams.rounded())) g")
                                }
                                Text("· " + item.statusText)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Nutrition Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
