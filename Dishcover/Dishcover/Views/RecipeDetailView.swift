import SwiftUI

/// Full recipe: photo, diet check, macros, ingredients (marked have / missing and flagged if they
/// break the user's diet), step-by-step tutorial, a favorite button, and a shortcut to find stores.
struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(PantryViewModel.self) private var pantry
    @Environment(FavoritesViewModel.self) private var favorites
    @Environment(NutritionViewModel.self) private var nutrition
    @Environment(DietProfileViewModel.self) private var diet

    private var match: PantryMatch {
        RecipeSearchViewModel.match(recipe, pantry: pantry.ingredientNames)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if diet.isActive {
                    DietBanner(conflicts: diet.conflicts(for: recipe),
                               missedGoals: diet.missedGoals(for: nutrition.perServing(for: recipe)),
                               profileSummary: diet.summary)
                }
                MacroPanel(estimate: nutrition.estimate(for: recipe),
                           servings: Binding(get: { nutrition.servings(for: recipe.id) },
                                             set: { nutrition.setServings($0, for: recipe.id) }))
                ingredientsSection
                if !match.missing.isEmpty { findStoresButton }
                instructionsSection
                if let youtube = recipe.youtubeURL {
                    Link(destination: youtube) {
                        Label("Watch video tutorial", systemImage: "play.rectangle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favorites.toggle(recipe)
                } label: {
                    Image(systemName: favorites.isFavorite(recipe.id) ? "heart.fill" : "heart")
                        .foregroundStyle(.red)
                }
                .accessibilityLabel(favorites.isFavorite(recipe.id) ? "Remove from favorites" : "Add to favorites")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: recipe.thumbnailURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.orange.opacity(0.15)
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(recipe.name).font(.title2.bold())
            HStack {
                if let category = recipe.category { Tag(text: category) }
                if let area = recipe.area { Tag(text: area) }
                Label(recipe.estimatedTimeText, systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(match.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var ingredientsSection: some View {
        let flagged = diet.flaggedIngredients(for: recipe)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients").font(.headline)
            ForEach(match.have) { row($0, have: true, flagged: flagged.contains($0.name)) }
            ForEach(match.missing) { row($0, have: false, flagged: flagged.contains($0.name)) }
        }
    }

    private func row(_ ingredient: Ingredient, have: Bool, flagged: Bool) -> some View {
        HStack {
            Image(systemName: have ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(have ? .green : .secondary)
            Text(ingredient.name)
                .foregroundStyle(flagged ? .red : .primary)
            if flagged {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Doesn't fit your diet")
            }
            Spacer()
            Text(ingredient.measure).foregroundStyle(.secondary).font(.callout)
        }
    }

    private var findStoresButton: some View {
        NavigationLink {
            StoreMapView(missingIngredients: match.missing.map(\.name))
        } label: {
            Label("Find stores for \(match.missing.count) missing ingredient\(match.missing.count == 1 ? "" : "s")",
                  systemImage: "map")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to make it").font(.headline)
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(Color.orange, in: Circle())
                        .foregroundStyle(.white)
                    Text(step)
                }
            }
        }
    }
}

struct Tag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.12), in: Capsule())
            .foregroundStyle(.orange)
    }
}

/// Loads a recipe by id first (used by Favorites, which only stores id/name/image).
struct RecipeLoaderView: View {
    let recipeID: String
    @State private var recipe: Recipe?
    @State private var failed = false

    var body: some View {
        Group {
            if let recipe {
                RecipeDetailView(recipe: recipe)
            } else if failed {
                ContentUnavailableView("Couldn't load recipe", systemImage: "wifi.exclamationmark")
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                recipe = try await MealDBService().lookup(id: recipeID)
                failed = recipe == nil
            } catch {
                failed = true
            }
        }
    }
}
