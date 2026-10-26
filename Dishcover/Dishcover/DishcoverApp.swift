import SwiftUI
import SwiftData

@main
@MainActor
struct DishcoverApp: App {
    private let container: ModelContainer

    // ViewModels are created once and shared with every screen through the environment.
    @State private var searchVM: RecipeSearchViewModel
    @State private var pantryVM: PantryViewModel
    @State private var favoritesVM: FavoritesViewModel
    @State private var nutritionVM: NutritionViewModel
    @State private var dietVM: DietProfileViewModel

    init() {
        do {
            container = try ModelContainer(for: PantryItem.self, FavoriteRecipe.self, DietProfile.self)
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
        let context = container.mainContext
        let nutrition = NutritionViewModel()
        let diet = DietProfileViewModel(context: context)
        _nutritionVM = State(initialValue: nutrition)
        _dietVM = State(initialValue: diet)
        _searchVM = State(initialValue: RecipeSearchViewModel(diet: diet, nutrition: nutrition))
        _pantryVM = State(initialValue: PantryViewModel(context: context))
        _favoritesVM = State(initialValue: FavoritesViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(searchVM)
                .environment(pantryVM)
                .environment(favoritesVM)
                .environment(nutritionVM)
                .environment(dietVM)
        }
        .modelContainer(container)
    }
}
