import Foundation
import Observation
import SwiftData

/// Adds, removes and lists the ingredients the user has at home (stored with SwiftData).
@MainActor
@Observable
final class PantryViewModel {
    private(set) var items: [PantryItem] = []
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        load()
    }

    var ingredientNames: [String] { items.map(\.name) }

    /// One section of the pantry list, e.g. "Vegetables" with its items.
    struct PantrySection: Identifiable {
        let group: FoodGroup
        let items: [PantryItem]
        var id: FoodGroup { group }
    }

    /// Pantry items split into food groups (in the order of `FoodGroup.allCases`),
    /// leaving out groups with no items.
    var groupedItems: [PantrySection] {
        let byGroup = Dictionary(grouping: items, by: { $0.group })
        return FoodGroup.allCases.compactMap { group in
            guard let groupItems = byGroup[group], !groupItems.isEmpty else { return nil }
            return PantrySection(group: group, items: groupItems)
        }
    }

    /// Moves an item to a different group (the user's choice is saved and overrides the automatic one).
    func setGroup(_ group: FoodGroup, for item: PantryItem) {
        item.groupOverride = group == FoodGroup.classify(item.name) ? nil : group.rawValue
        save()
    }

    func load() {
        let descriptor = FetchDescriptor<PantryItem>(sortBy: [SortDescriptor(\.name)])
        items = (try? context.fetch(descriptor)) ?? []
    }

    /// Accepts a single ingredient or a comma-separated list ("eggs, milk, rice").
    func add(_ text: String) {
        let names = text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).capitalized }
            .filter { !$0.isEmpty }

        for name in names where !items.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            context.insert(PantryItem(name: name))
        }
        save()
    }

    func remove(_ item: PantryItem) {
        context.delete(item)
        save()
    }

    func remove(at offsets: IndexSet) {
        offsets.map { items[$0] }.forEach(context.delete)
        save()
    }

    func removeAll() {
        items.forEach(context.delete)
        save()
    }

    private func save() {
        try? context.save()
        load()
    }
}
