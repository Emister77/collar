import Foundation
import Observation
import SwiftData

/// Saves and removes favorited recipes on-device with SwiftData.
@MainActor
@Observable
final class FavoritesViewModel {
    private(set) var favorites: [FavoriteRecipe] = []
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        load()
    }

    func load() {
        let descriptor = FetchDescriptor<FavoriteRecipe>(sortBy: [SortDescriptor(\.dateSaved, order: .reverse)])
        favorites = (try? context.fetch(descriptor)) ?? []
    }

    func isFavorite(_ recipeID: String) -> Bool {
        favorites.contains { $0.recipeID == recipeID }
    }

    func toggle(_ recipe: Recipe) {
        if let existing = favorites.first(where: { $0.recipeID == recipe.id }) {
            context.delete(existing)
        } else {
            context.insert(FavoriteRecipe(recipe: recipe))
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        offsets.map { favorites[$0] }.forEach(context.delete)
        save()
    }

    private func save() {
        try? context.save()
        load()
    }
}
