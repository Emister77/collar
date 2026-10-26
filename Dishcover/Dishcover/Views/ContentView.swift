import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            PantryView()
                .tabItem { Label("Pantry", systemImage: "refrigerator") }

            RandomRecipeView()
                .tabItem { Label("Random", systemImage: "dice") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }

            DietProfileView()
                .tabItem { Label("My Diet", systemImage: "person.crop.circle") }
        }
        .tint(.orange)
    }
}
