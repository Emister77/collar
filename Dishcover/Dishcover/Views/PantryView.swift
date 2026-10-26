import SwiftUI

/// Lets the user record what ingredients they have, sorted into food groups with an icon
/// next to each one. Saved with SwiftData.
struct PantryView: View {
    @Environment(PantryViewModel.self) private var pantry
    @State private var newItem = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add ingredient (or a comma-separated list)", text: $newItem)
                            .focused($fieldFocused)
                            .submitLabel(.done)
                            .onSubmit(add)
                        Button(action: add) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } footer: {
                    if !pantry.items.isEmpty {
                        Text("\(pantry.items.count) ingredient\(pantry.items.count == 1 ? "" : "s") · Long-press an item to move it to another group.")
                    }
                }

                if pantry.items.isEmpty {
                    Section {
                        Text("Nothing here yet. Try “eggs, rice, chicken”.")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(pantry.groupedItems) { section in
                    Section {
                        ForEach(section.items) { item in
                            row(for: item)
                        }
                        .onDelete { offsets in
                            offsets.map { section.items[$0] }.forEach { pantry.remove($0) }
                        }
                    } header: {
                        Text("\(section.group.emoji)  \(section.group.title) (\(section.items.count))")
                    }
                }
            }
            .navigationTitle("My Pantry")
            .toolbar {
                if !pantry.items.isEmpty { EditButton() }
            }
        }
    }

    private func row(for item: PantryItem) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.orange.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text(item.name)
        }
        .contextMenu {
            Menu("Move to") {
                ForEach(FoodGroup.allCases) { group in
                    Button {
                        pantry.setGroup(group, for: item)
                    } label: {
                        if group == item.group {
                            Label("\(group.emoji) \(group.title)", systemImage: "checkmark")
                        } else {
                            Text("\(group.emoji) \(group.title)")
                        }
                    }
                }
            }
            Button(role: .destructive) {
                pantry.remove(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func add() {
        pantry.add(newItem)
        newItem = ""
        fieldFocused = true
    }
}
