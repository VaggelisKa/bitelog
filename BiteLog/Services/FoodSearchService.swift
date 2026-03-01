import Foundation
import SwiftData

@Observable
final class FoodSearchService {
    var searchResults: [OpenFoodFactsProduct] = []
    var isSearching = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    private static let baseURL = "https://world.openfoodfacts.org"
    private static let userAgent = "BiteLog/1.0 (iOS; contact@bitelog.app)"

    func search(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            do {
                let results = try await performSearch(query: query)
                if !Task.isCancelled {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Search failed. Check your connection."
                    isSearching = false
                }
            }
        }
    }

    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        isSearching = false
        errorMessage = nil
    }

    private func performSearch(query: String) async throws -> [OpenFoodFactsProduct] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(Self.baseURL)/cgi/search.pl?search_terms=\(encoded)&search_simple=1&json=1&countries_tags_en=denmark&page_size=30"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)

        return response.products.filter { product in
            product.productName != nil && product.nutriments?.energyKcal100g != nil
        }
    }

    func createFoodItem(from product: OpenFoodFactsProduct) -> FoodItem {
        let nutriments = product.nutriments
        return FoodItem(
            name: product.productName ?? "Unknown",
            brand: product.brands,
            barcode: product.code,
            caloriesPer100g: nutriments?.energyKcal100g ?? 0,
            proteinPer100g: nutriments?.proteins100g ?? 0,
            carbsPer100g: nutriments?.carbohydrates100g ?? 0,
            fatPer100g: nutriments?.fat100g ?? 0,
            defaultServingG: product.servingQuantityG,
            servingDescription: product.servingSize
        )
    }
}

// MARK: - API Response Models

struct OpenFoodFactsResponse: Decodable {
    let products: [OpenFoodFactsProduct]
}

struct OpenFoodFactsProduct: Decodable, Identifiable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let servingQuantityG: Double?
    let nutriments: OFFNutriments?

    var id: String { code ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantityG = "serving_quantity"
        case nutriments
    }
}

struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}
