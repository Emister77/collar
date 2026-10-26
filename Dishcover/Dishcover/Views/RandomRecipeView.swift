import SwiftUI

/// "Surprise me" — fetches a random recipe from TheMealDB.
struct RandomRecipeView: View {
    @Environment(RecipeSearchViewModel.self) private var search
    @Environment(PantryViewModel.self) private var pantry
    @Environment(NutritionViewModel.self) private var nutrition
    @Environment(DietProfileViewModel.self) private var diet

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let recipe = search.randomRecipe {
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        card(for: recipe)
                    }
                    .buttonStyle(.plain)
                } else if search.isLoading {
                    ProgressView().frame(maxHeight: .infinity)
                } else {
                    ContentUnavailableView("Not sure what to cook?",
                                           systemImage: "dice",
                                           description: Text("Tap the button for a random recipe."))
                }

                Button {
                    Task { await search.fetchRandom() }
                } label: {
                    Label(search.randomRecipe == nil ? "Surprise Me" : "Try Another", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(search.isLoading)
            }
            .padding()
            .navigationTitle("Random Recipe")
        }
    }

    private func card(for recipe: Recipe) -> some View {
        let match = RecipeSearchViewModel.match(recipe, pantry: pantry.ingredientNames)
        return VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: recipe.thumbnailURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.orange.opacity(0.15)
            }
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(recipe.name).font(.title2.bold())
            HStack {
                if let category = recipe.category { Tag(text: category) }
                if let area = recipe.area { Tag(text: area) }
                Label(recipe.estimatedTimeText, systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(match.summary).font(.subheadline).foregroundStyle(.secondary)
            MacroLine(macros: nutrition.perServing(for: recipe), confidence: nutrition.estimate(for: recipe).confidence)
            DietWarningBadge(conflicts: diet.conflicts(for: recipe),
                             missedGoals: diet.missedGoals(for: nutrition.perServing(for: recipe)))
            Text("Tap to see the full recipe →").font(.footnote).foregroundStyle(.orange)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
