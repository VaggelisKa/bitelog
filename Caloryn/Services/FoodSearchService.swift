import Foundation
import SwiftData

/// Food search powered by the Search-a-licious API (search.openfoodfacts.org).
/// We delegate full-text ranking entirely to the API's Elasticsearch backend
/// and keep only a thin country-scoped → global fallback strategy client-side.
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
        "nutriments",
        "nutrition_grades",
        "lang",
        "countries_tags"
    ].joined(separator: ",")

    private static let pageSize = 30
    private static let countryMinResultsForSkipGlobal = 6

    // MARK: - Public API

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
        return FoodItem(
            name: product.productName ?? "Unknown",
            brand: product.brands,
            barcode: product.code,
            caloriesPer100g: nutriments?.energyKcal100g ?? 0,
            proteinPer100g: nutriments?.proteins100g ?? 0,
            carbsPer100g: nutriments?.carbohydrates100g ?? 0,
            fatPer100g: nutriments?.fat100g ?? 0,
            defaultServingG: product.servingQuantityG,
            servingDescription: product.formattedServingDescription,
            nutriscoreGrade: Self.validNutriscoreGrade(product.nutritionGrades)
        )
    }

    // MARK: - Search Strategy

    /// Country-scoped search first; fall back to global if too few results.
    /// Ranking is fully delegated to Search-a-licious (Elasticsearch).
    private func performSearch(query: String) async {
        let locale = SearchLocaleContext.current

        if let countryQuery = buildCountryQuery(query: query, locale: locale) {
            let countryResults = (try? await fetchResults(query: countryQuery, locale: locale)) ?? []
            guard !Task.isCancelled else { return }

            if countryResults.count >= Self.countryMinResultsForSkipGlobal {
                searchResults = countryResults
                isSearching = false
                return
            }

            if !countryResults.isEmpty {
                searchResults = countryResults
            }

            let globalResults = (try? await fetchResults(query: query, locale: locale)) ?? []
            guard !Task.isCancelled else { return }

            searchResults = mergeResults(primary: countryResults, secondary: globalResults)
            isSearching = false
        } else {
            let results = (try? await fetchResults(query: query, locale: locale)) ?? []
            guard !Task.isCancelled else { return }

            searchResults = results
            isSearching = false
        }
    }

    // MARK: - Network

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

    // MARK: - Merge (preserves API ordering, deduplicates by barcode)

    private func mergeResults(
        primary: [OpenFoodFactsProduct],
        secondary: [OpenFoodFactsProduct]
    ) -> [OpenFoodFactsProduct] {
        var seen = Set<String>()
        var merged: [OpenFoodFactsProduct] = []

        for product in primary {
            if let code = product.code, seen.insert(code).inserted {
                merged.append(product)
            } else if product.code == nil {
                merged.append(product)
            }
        }
        for product in secondary {
            if let code = product.code, seen.insert(code).inserted {
                merged.append(product)
            } else if product.code == nil {
                merged.append(product)
            }
        }

        return merged
    }

    // MARK: - Country Query

    private func buildCountryQuery(
        query: String,
        locale: SearchLocaleContext
    ) -> String? {
        guard
            let countryTag = locale.preferredCountryTag,
            let safeTag = sanitizedCountryTag(countryTag)
        else { return nil }

        let escaped = escapeLuceneSpecials(query)
        guard !escaped.isEmpty else { return nil }

        return #"countries_tags:"\#(safeTag)" \#(escaped)"#
    }

    private func sanitizedCountryTag(_ tag: String) -> String? {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789:-")
        guard tag.unicodeScalars.allSatisfy(allowed.contains) else { return nil }
        return tag
    }

    private func escapeLuceneSpecials(_ text: String) -> String {
        let reserved = Set(#"+-!(){}[]^"~*?:\/&|"#.map(\.self))
        var escaped = ""
        for ch in text {
            if reserved.contains(ch) { escaped.append("\\") }
            escaped.append(ch)
        }
        return escaped
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    private static func validNutriscoreGrade(_ raw: String?) -> String? {
        guard let letter = raw?.lowercased(), ["a", "b", "c", "d", "e"].contains(letter) else { return nil }
        return letter
    }

    // MARK: - Locale

    private struct SearchLocaleContext {
        let preferredLanguageCodes: [String]
        let preferredCountryTag: String?

        static var current: SearchLocaleContext {
            let codes = orderedUnique(
                Locale.preferredLanguages.compactMap(languageCode(from:)) + ["en"]
            )
            let country = Locale.autoupdatingCurrent.regionCode.flatMap(countryTag(from:))
            return SearchLocaleContext(preferredLanguageCodes: codes, preferredCountryTag: country)
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

        private static func countryTag(from regionCode: String) -> String? {
            let en = Locale(identifier: "en_US_POSIX")
            guard let name = en.localizedString(forRegionCode: regionCode) else { return nil }

            let slug = name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: en)
                .replacingOccurrences(of: "&", with: " and ")
                .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

            guard !slug.isEmpty else { return nil }
            return "en:\(slug)"
        }
    }
}

// MARK: - API Response Models

struct SearchResponse: Decodable {
    let hits: [OpenFoodFactsProduct]
}

struct OpenFoodFactsProduct: Decodable, Identifiable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let servingQuantityG: Double?
    let productQuantity: Double?
    let nutriments: OFFNutriments?
    let nutritionGrades: String?
    let lang: String?
    let countriesTags: [String]?

    var id: String { code ?? UUID().uuidString }

    /// Human-readable serving description, e.g. "1 slice (30g)" or "30g".
    var formattedServingDescription: String? {
        if let raw = servingSize, !raw.isEmpty {
            return raw
        }
        if let g = servingQuantityG, g > 0 {
            return "\(Int(g))g"
        }
        return nil
    }

    /// Calories per serving (if serving weight is known), for display in result rows.
    var caloriesPerServing: Double? {
        guard let g = servingQuantityG, g > 0,
              let kcal100 = nutriments?.energyKcal100g else { return nil }
        return kcal100 * g / 100
    }

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantityG = "serving_quantity"
        case productQuantity = "product_quantity"
        case nutriments
        case nutritionGrades = "nutrition_grades"
        case lang
        case countriesTags = "countries_tags"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)
        nutriments = try container.decodeIfPresent(OFFNutriments.self, forKey: .nutriments)
        nutritionGrades = try container.decodeIfPresent(String.self, forKey: .nutritionGrades)
        lang = try container.decodeIfPresent(String.self, forKey: .lang)
        countriesTags = try container.decodeIfPresent([String].self, forKey: .countriesTags)

        // serving_quantity may arrive as a number or a numeric string
        if let num = try? container.decodeIfPresent(Double.self, forKey: .servingQuantityG) {
            servingQuantityG = num
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .servingQuantityG) {
            servingQuantityG = Double(str)
        } else {
            servingQuantityG = nil
        }

        // product_quantity may arrive as a number or a numeric string
        if let num = try? container.decodeIfPresent(Double.self, forKey: .productQuantity) {
            productQuantity = num
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .productQuantity) {
            productQuantity = Double(str)
        } else {
            productQuantity = nil
        }

        // Search-a-licious returns brands as [String]; the barcode API returns String
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
