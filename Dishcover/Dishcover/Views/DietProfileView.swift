import SwiftUI

/// "My Diet" tab: diets, allergies, custom exclusions, nutrition goals, and hide-vs-warn mode.
/// Everything is saved on the device with SwiftData.
struct DietProfileView: View {
    @Environment(DietProfileViewModel.self) private var diet
    @State private var newExclusion = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(get: { diet.hideConflicts }, set: { diet.setHideConflicts($0) })) {
                        Label("Hide recipes that don't fit", systemImage: "eye.slash")
                    }
                    .tint(.orange)
                } footer: {
                    Text(diet.hideConflicts
                         ? "Recipes that break your diet won't appear in search results."
                         : "Recipes that break your diet still appear, marked with a red warning.")
                }

                Section("Diets") {
                    ForEach(DietaryRestriction.diets) { restriction in
                        toggleRow(restriction)
                    }
                }

                Section("Allergies") {
                    ForEach(DietaryRestriction.allergies) { restriction in
                        toggleRow(restriction)
                    }
                }

                Section {
                    HStack {
                        TextField("e.g. mushrooms, cilantro", text: $newExclusion)
                            .onSubmit(addExclusion)
                        Button(action: addExclusion) {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                        .disabled(newExclusion.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ForEach(diet.customExclusions, id: \.self) { word in
                        Label(word.capitalized, systemImage: "nosign")
                    }
                    .onDelete { offsets in
                        offsets.map { diet.customExclusions[$0] }.forEach(diet.removeExclusion)
                    }
                } header: {
                    Text("Never show these ingredients")
                }

                Section {
                    ForEach(NutritionGoal.allCases) { goal in
                        Toggle(goal.title, isOn: Binding(get: { diet.goals.contains(goal) }, set: { _ in diet.toggle(goal) }))
                            .tint(.orange)
                    }
                    if diet.goals.contains(.calorieLimit) {
                        Stepper("Max \(diet.calorieLimit) kcal per serving",
                                value: Binding(get: { diet.calorieLimit }, set: { diet.setCalorieLimit($0) }),
                                in: 100...2000, step: 50)
                    }
                } header: {
                    Text("Nutrition goals (per serving)")
                } footer: {
                    Text("Goals use the estimated macros, so they're approximate.")
                }

                Section {
                    Label("Dishcover checks ingredient names and can miss hidden ingredients. "
                          + "If you have a severe allergy, always check product labels.",
                          systemImage: "exclamationmark.shield")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("My Diet")
        }
    }

    private func toggleRow(_ restriction: DietaryRestriction) -> some View {
        Toggle(restriction.title, isOn: Binding(get: { diet.restrictions.contains(restriction) },
                                                set: { _ in diet.toggle(restriction) }))
            .tint(.orange)
    }

    private func addExclusion() {
        diet.addExclusion(newExclusion)
        newExclusion = ""
    }
}
