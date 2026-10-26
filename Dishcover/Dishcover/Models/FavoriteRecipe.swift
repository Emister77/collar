import Foundation
import SwiftData

/// A recipe the user has favorited. Only the fields needed to show it in the
/// Favorites list are stored; full details are re-fetched from TheMealDB by id.
@Model
final class FavoriteRecipe {
    @Attribute(.unique) var recipeID: String
    var name: String
    var category: String?
    var thumbnailURL: String?
    var dateSaved: Date

    init(recipeID: String, name: String, category: String?, thumbnailURL: String?, dateSaved: Date = .now) {
        self.recipeID = recipeID
        self.name = name
        self.category = category
        self.thumbnailURL = thumbnailURL
        self.dateSaved = dateSaved
    }

    convenience init(recipe: Recipe) {
        self.init(recipeID: recipe.id,
                  name: recipe.name,
                  category: recipe.category,
                  thumbnailURL: recipe.thumbnailURL?.absoluteString)
    }
}
