import SwiftUI

/// Recipes the user saved. Stored locally with SwiftData.
struct FavoritesView: View {
    @Environment(FavoritesViewModel.self) private var favorites

    var body: some View {
        NavigationStack {
            Group {
                if favorites.favorites.isEmpty {
                    ContentUnavailableView("No favorites yet",
                                           systemImage: "heart",
                                           description: Text("Tap the heart on any recipe to save it here."))
                } else {
                    List {
                        ForEach(favorites.favorites) { favorite in
                            NavigationLink {
                                RecipeLoaderView(recipeID: favorite.recipeID)
                            } label: {
                                HStack(spacing: 12) {
                                    RecipeThumbnail(url: favorite.thumbnailURL.flatMap(URL.init(string:)), size: 56)
                                    VStack(alignment: .leading) {
                                        Text(favorite.name).font(.headline)
                                        Text("Saved \(favorite.dateSaved.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: favorites.remove(at:))
                    }
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
