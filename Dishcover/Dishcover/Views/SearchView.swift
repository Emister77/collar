import SwiftUI

/// Home screen: search by recipe name, or by the ingredients saved in the pantry,
/// optionally filtered by cuisine, meal type, estimated cook time and the user's dietary profile.
struct SearchView: View {
    @Environment(RecipeSearchViewModel.self) private var search
    @Environment(PantryViewModel.self) private var pantry
    @Environment(NutritionViewModel.self) private var nutrition
    @Environment(DietProfileViewModel.self) private var diet

    var body: some View {
        @Bindable var search = search

        NavigationStack {
            List {
                Section {
                    Picker("Search mode", selection: $search.mode) {
                        ForEach(RecipeSearchViewModel.Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if search.mode == .name {
                    nameSection
                } else {
                    ingredientSection
                }

                filterSection

                if search.mode == .ingredients && !pantry.items.isEmpty {
                    Section {
                        Button {
                            Task { await search.searchByIngredients(pantry: pantry.ingredientNames) }
                        } label: {
                            Label("Find Recipes", systemImage: "fork.knife")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }

                resultsSection
            }
            .navigationTitle("Find Recipes")
            .task { await search.loadCuisines() }
            .overlay {
                if search.isLoading { ProgressView("Searching…") }
            }
        }
    }

    // MARK: - Name search

    @ViewBuilder
    private var nameSection: some View {
        @Bindable var search = search
        Section {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("e.g. Lasagne, Teriyaki Chicken", text: $search.query)
                    .submitLabel(.search)
                    .onSubmit { Task { await search.searchByName() } }
            }
        }
    }

    // MARK: - Ingredient search

    @ViewBuilder
    private var ingredientSection: some View {
        Section {
            if pantry.items.isEmpty {
                ContentUnavailableView("Your pantry is empty",
                                       systemImage: "refrigerator",
                                       description: Text("Add what you have in the Pantry tab, then come back here."))
            } else {
                Text("Tap to choose ingredients (none selected = use all)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 8) {
                    ForEach(pantry.ingredientNames, id: \.self) { name in
                        IngredientChip(name: name, isSelected: search.selectedIngredients.contains(name)) {
                            if search.selectedIngredients.contains(name) {
                                search.selectedIngredients.remove(name)
                            } else {
                                search.selectedIngredients.insert(name)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("What do you have?")
        }
    }

    // MARK: - Filters

    @ViewBuilder
    private var filterSection: some View {
        @Bindable var search = search
        Section {
            Picker(selection: $search.selectedCuisine) {
                Text("Any cuisine").tag(String?.none)
                ForEach(search.cuisines, id: \.self) { cuisine in
                    Text(cuisine).tag(String?.some(cuisine))
                }
            } label: {
                Label("Cuisine", systemImage: "globe")
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Meal type", systemImage: "menucard")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MealType.allCases) { type in
                            IngredientChip(name: type.rawValue, isSelected: search.mealType == type) {
                                search.mealType = type
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Cook time", systemImage: "timer")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CookTimeRange.allCases) { range in
                            IngredientChip(name: range.rawValue, isSelected: search.cookTime == range) {
                                search.cookTime = range
                            }
                        }
                    }
                }
            }

            if diet.isActive {
                Toggle(isOn: $search.respectDiet) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Respect my diet", systemImage: "person.crop.circle.badge.checkmark")
                        Text(diet.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
                .tint(.orange)
            } else {
                Label("Set up diets and allergies in the My Diet tab", systemImage: "person.crop.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("Filters")
                Spacer()
                if search.hasActiveFilters {
                    Button("Clear") { search.clearFilters() }
                        .font(.caption)
                        .textCase(nil)
                }
            }
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        if let message = search.errorMessage {
            Section { Label(message, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
        } else if search.hasSearched && search.results.isEmpty && !search.isLoading {
            Section {
                Text(search.respectDiet && diet.isActive
                     ? "No recipes match your filters and diet. Try changing a filter, or turn off “Respect my diet”."
                     : search.hasActiveFilters
                        ? "No recipes match these filters. Try a different cuisine or meal type."
                        : "No recipes found. Try another search.")
                    .foregroundStyle(.secondary)
            }
        } else if !search.results.isEmpty {
            Section {
                ForEach(search.results) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeRowView(recipe: recipe,
                                      match: RecipeSearchViewModel.match(recipe, pantry: pantry.ingredientNames),
                                      macros: nutrition.perServing(for: recipe),
                                      macroConfidence: nutrition.estimate(for: recipe).confidence,
                                      dietConflicts: diet.conflicts(for: recipe),
                                      missedGoals: diet.missedGoals(for: nutrition.perServing(for: recipe)))
                    }
                }
            } header: {
                Text(search.hasActiveFilters
                     ? "\(search.results.count) recipes · \(search.filterSummary)"
                     : "\(search.results.count) recipes")
            }
        }
    }
}

/// A selectable pill used for pantry ingredients.
struct IngredientChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color.orange.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? .white : .orange)
        }
        .buttonStyle(.plain)
    }
}

/// Simple wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
