import Foundation
import SwiftData

@Observable
final class FoodSearchService {
    var searchResults: [OpenFoodFactsProduct] = []
    var isSearching = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    private static let searchBaseURL = "https://search.openfoodfacts.org"
    private static let barcodeBaseURL = "https://world.openfoodfacts.org"
    private static let userAgent = "Caloryn/1.0 (iOS; contact@caloryn.app)"

    private static let searchFields = [
        "code",
        "product_name",
        "brands",
        "serving_size",
        "serving_quantity",
        "product_quantity",
        "quantity",
        "nutriments",
        "nutrition_grades",
        "lang",
        "countries_tags"
    ].joined(separator: ",")

    private static let pageSize = 30

    func search(query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            await performSearch(query: trimmed)
        }
    }

    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        isSearching = false
        errorMessage = nil
    }

    func lookupBarcode(_ code: String) async throws -> OpenFoodFactsProduct {
        let urlString = "\(Self.barcodeBaseURL)/api/v0/product/\(code).json"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BarcodeLookupResponse.self, from: data)

        guard response.status == 1, let product = response.product,
              product.productName != nil, product.nutriments?.energyKcal100g != nil else {
            throw BarcodeLookupError.productNotFound
        }

        return product
    }

    func createFoodItem(from product: OpenFoodFactsProduct) -> FoodItem {
        let nutriments = product.nutriments
        let (defaultServingG, servingDescription) = product.effectiveServingInfo
        return FoodItem(
            name: product.productName ?? "Unknown",
            brand: product.brands,
            barcode: product.code,
            caloriesPer100g: nutriments?.energyKcal100g ?? 0,
            proteinPer100g: nutriments?.proteins100g ?? 0,
            carbsPer100g: nutriments?.carbohydrates100g ?? 0,
            fatPer100g: nutriments?.fat100g ?? 0,
            defaultServingG: defaultServingG,
            servingDescription: servingDescription,
            nutriscoreGrade: Self.validNutriscoreGrade(product.nutritionGrades)
        )
    }

    private func performSearch(query: String) async {
        let locale = SearchLocaleContext.current
        let results = (try? await fetchResults(query: query, locale: locale)) ?? []
        guard !Task.isCancelled else { return }

        searchResults = results
        isSearching = false
    }

    private func fetchResults(
        query: String,
        locale: SearchLocaleContext
    ) async throws -> [OpenFoodFactsProduct] {
        var components = URLComponents(string: "\(Self.searchBaseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: Self.searchFields),
            URLQueryItem(name: "page_size", value: String(Self.pageSize)),
            URLQueryItem(name: "langs", value: locale.preferredLanguageCodes.joined(separator: ","))
        ]

        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        return response.hits.filter { $0.productName != nil && $0.nutriments?.energyKcal100g != nil }
    }

    private static func validNutriscoreGrade(_ raw: String?) -> String? {
        guard let letter = raw?.lowercased(), ["a", "b", "c", "d", "e"].contains(letter) else { return nil }
        return letter
    }

    private struct SearchLocaleContext {
        let preferredLanguageCodes: [String]

        static var current: SearchLocaleContext {
            let codes = orderedUnique(
                Locale.preferredLanguages.compactMap(languageCode(from:)) + ["en"]
            )
            return SearchLocaleContext(preferredLanguageCodes: codes)
        }

        private static func orderedUnique(_ values: [String]) -> [String] {
            var seen = Set<String>()
            return values.compactMap { value in
                let norm = value.lowercased()
                guard seen.insert(norm).inserted else { return nil }
                return norm
            }
        }

        private static func languageCode(from identifier: String) -> String? {
            identifier
                .split(whereSeparator: { $0 == "-" || $0 == "_" })
                .first?
                .lowercased()
        }
    }
}

struct SearchResponse: Decodable {
    let hits: [OpenFoodFactsProduct]
}

struct OpenFoodFactsProduct: Decodable, Identifiable, Hashable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let servingQuantityG: Double?
    let productQuantity: Double?
    let quantity: String?
    let nutriments: OFFNutriments?
    let nutritionGrades: String?
    let lang: String?
    let countriesTags: [String]?

    /// Stable identity stored once at decode time so ForEach/navigation never sees a shifting id.
    private let stableId: String
    var id: String { stableId }

    /// Parses grams from quantity strings like "350g", "50 g", "1 oz (28 g)".
    private var quantityGrams: Double? {
        guard let q = quantity, !q.isEmpty else { return nil }
        let pattern = #"(\d+(?:[.,]\d+)?)\s*g\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(q.startIndex..., in: q)
        guard let match = regex.firstMatch(in: q, range: range), match.numberOfRanges > 1 else { return nil }
        let numRange = match.range(at: 1)
        guard let swiftRange = Range(numRange, in: q) else { return nil }
        let numStr = String(q[swiftRange]).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(numStr), value > 0 else { return nil }
        return value
    }

    var formattedServingDescription: String? {
        if let raw = servingSize, !raw.isEmpty {
            return raw
        }
        if let g = servingQuantityG, g > 0 {
            return "\(Int(g))g"
        }
        return nil
    }

    /// Serving info with fallbacks: serving_quantity → product_quantity → parsed quantity string.
    var effectiveServingInfo: (defaultServingG: Double?, servingDescription: String?) {
        if let g = servingQuantityG, g > 0 {
            return (g, formattedServingDescription)
        }
        if let packG = productQuantity, packG > 0 {
            return (packG, "1 pack (\(Int(packG))g)")
        }
        if let packG = quantityGrams {
            return (packG, "1 pack (\(Int(packG))g)")
        }
        return (nil, nil)
    }

    var caloriesPerServing: Double? {
        let g = servingQuantityG ?? productQuantity ?? quantityGrams
        guard let grams = g, grams > 0,
              let kcal100 = nutriments?.energyKcal100g else { return nil }
        return kcal100 * grams / 100
    }

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantityG = "serving_quantity"
        case productQuantity = "product_quantity"
        case quantity
        case nutriments
        case nutritionGrades = "nutrition_grades"
        case lang
        case countriesTags = "countries_tags"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedCode = try container.decodeIfPresent(String.self, forKey: .code)
        code = decodedCode
        stableId = decodedCode ?? UUID().uuidString
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        nutriments = try container.decodeIfPresent(OFFNutriments.self, forKey: .nutriments)
        nutritionGrades = try container.decodeIfPresent(String.self, forKey: .nutritionGrades)
        lang = try container.decodeIfPresent(String.self, forKey: .lang)
        countriesTags = try container.decodeIfPresent([String].self, forKey: .countriesTags)

        if let num = try? container.decodeIfPresent(Double.self, forKey: .servingQuantityG) {
            servingQuantityG = num
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .servingQuantityG) {
            servingQuantityG = Double(str)
        } else {
            servingQuantityG = nil
        }

        if let num = try? container.decodeIfPresent(Double.self, forKey: .productQuantity) {
            productQuantity = num
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .productQuantity) {
            productQuantity = Double(str)
        } else {
            productQuantity = nil
        }

        if let str = try? container.decodeIfPresent(String.self, forKey: .brands) {
            brands = str
        } else if let arr = try? container.decodeIfPresent([String].self, forKey: .brands) {
            brands = arr.joined(separator: ", ")
        } else {
            brands = nil
        }
    }
}

struct BarcodeLookupResponse: Decodable {
    let code: String?
    let status: Int
    let product: OpenFoodFactsProduct?
}

enum BarcodeLookupError: LocalizedError {
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            "Product not found for this barcode."
        }
    }
}

struct OFFNutriments: Decodable, Hashable {
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
