import Foundation

enum MealDBError: LocalizedError {
    case badURL
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Could not build the request URL."
        case .badResponse(let code): return "TheMealDB returned an error (HTTP \(code))."
        }
    }
}

/// Thin networking layer over TheMealDB's free public JSON API.
/// Docs: https://www.themealdb.com/api.php  (test key "1")
struct MealDBService {
    private let base = "https://www.themealdb.com/api/json/v1/1/"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// search.php?s=  -> full recipes whose name matches.
    func searchByName(_ name: String) async throws -> [Recipe] {
        let response: MealsResponse<Recipe> = try await get("search.php", query: ["s": name])
        return response.meals ?? []
    }

    /// filter.php?i=  -> only id/name/image of meals that use the ingredient.
    func filterByIngredient(_ ingredient: String) async throws -> [MealSummary] {
        let formatted = ingredient.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
        let response: MealsResponse<MealSummary> = try await get("filter.php", query: ["i": formatted])
        return response.meals ?? []
    }

    /// list.php?a=list  -> every cuisine ("area") TheMealDB knows about, e.g. Italian, Chinese.
    func listCuisines() async throws -> [String] {
        struct Area: Decodable { let strArea: String }
        let response: MealsResponse<Area> = try await get("list.php", query: ["a": "list"])
        return (response.meals ?? [])
            .map(\.strArea)
            .filter { $0 != "Unknown" }
            .sorted()
    }

    /// filter.php?a=  -> id/name/image of every meal from one cuisine.
    func filterByCuisine(_ cuisine: String) async throws -> [MealSummary] {
        let response: MealsResponse<MealSummary> = try await get("filter.php", query: ["a": cuisine])
        return response.meals ?? []
    }

    /// filter.php?c=  -> id/name/image of every meal in one category (e.g. Breakfast, Dessert).
    func filterByCategory(_ category: String) async throws -> [MealSummary] {
        let response: MealsResponse<MealSummary> = try await get("filter.php", query: ["c": category])
        return response.meals ?? []
    }

    /// lookup.php?i=  -> full details (ingredients + instructions) for one meal.
    func lookup(id: String) async throws -> Recipe? {
        let response: MealsResponse<Recipe> = try await get("lookup.php", query: ["i": id])
        return response.meals?.first
    }

    /// random.php  -> one random full recipe.
    func random() async throws -> Recipe? {
        let response: MealsResponse<Recipe> = try await get("random.php", query: [:])
        return response.meals?.first
    }

    private func get<T: Decodable>(_ endpoint: String, query: [String: String]) async throws -> T {
        guard var components = URLComponents(string: base + endpoint) else { throw MealDBError.badURL }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw MealDBError.badURL }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw MealDBError.badResponse(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
