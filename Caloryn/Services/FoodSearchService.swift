import Foundation
import SwiftData

@Observable
final class FoodSearchService {
    var searchResults: [OpenFoodFactsProduct] = []
    var isSearching = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    private static let baseURL = "https://world.openfoodfacts.org"
    private static let searchBaseURL = "https://search.openfoodfacts.org"
    private static let userAgent = "Caloryn/1.0 (iOS; contact@caloryn.app)"

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

    func lookupBarcode(_ code: String) async throws -> OpenFoodFactsProduct {
        let urlString = "\(Self.baseURL)/api/v0/product/\(code).json"

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

    private static let searchFields = [
        "code",
        "product_name",
        "brands",
        "serving_size",
        "serving_quantity",
        "nutriments",
        "lang",
        "countries_tags"
    ].joined(separator: ",")
    private static let searchPageSize = 48

    private func performSearch(query: String) async throws -> [OpenFoodFactsProduct] {
        let localeContext = SearchLocaleContext.current
        var components = URLComponents(string: "\(Self.searchBaseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: Self.searchFields),
            URLQueryItem(name: "page_size", value: String(Self.searchPageSize)),
            URLQueryItem(name: "langs", value: localeContext.preferredLanguageCodes.joined(separator: ","))
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        let candidates = response.hits.filter { hit in
            hit.productName != nil && hit.nutriments?.energyKcal100g != nil
        }

        return rankResults(candidates, for: query, localeContext: localeContext)
    }

    // The API relevance can surface foreign-language matches early, so we
    // re-rank candidates toward the user's query, language, and region.
    private func rankResults(
        _ products: [OpenFoodFactsProduct],
        for query: String,
        localeContext: SearchLocaleContext
    ) -> [OpenFoodFactsProduct] {
        let normalizedQuery = normalizeSearchText(query)
        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)

        return products.enumerated()
            .sorted { lhs, rhs in
                let leftScore = score(
                    lhs.element,
                    normalizedQuery: normalizedQuery,
                    queryTokens: queryTokens,
                    localeContext: localeContext,
                    originalIndex: lhs.offset
                )
                let rightScore = score(
                    rhs.element,
                    normalizedQuery: normalizedQuery,
                    queryTokens: queryTokens,
                    localeContext: localeContext,
                    originalIndex: rhs.offset
                )

                if leftScore == rightScore {
                    return lhs.offset < rhs.offset
                }

                return leftScore > rightScore
            }
            .map { $0.element }
    }

    private func score(
        _ product: OpenFoodFactsProduct,
        normalizedQuery: String,
        queryTokens: [String],
        localeContext: SearchLocaleContext,
        originalIndex: Int
    ) -> Int {
        let normalizedName = normalizeSearchText(product.productName ?? "")
        let normalizedBrand = normalizeSearchText(product.brands ?? "")
        let productLanguage = product.lang?.lowercased()

        var score = 0

        if !normalizedQuery.isEmpty {
            if normalizedName == normalizedQuery {
                score += 1_200
            } else if normalizedName.hasPrefix(normalizedQuery) {
                score += 900
            } else if normalizedName.contains(normalizedQuery) {
                score += 700
            }

            if normalizedBrand.contains(normalizedQuery) {
                score += 180
            }

            for token in queryTokens where !token.isEmpty {
                if normalizedName.contains(token) {
                    score += 120
                }
                if normalizedBrand.contains(token) {
                    score += 40
                }
            }
        }

        if let productLanguage {
            if localeContext.preferredLanguageCodes.first == productLanguage {
                score += 325
            } else if localeContext.preferredLanguageCodes.contains(productLanguage) {
                score += 240
            }
        }

        if let preferredCountryTag = localeContext.preferredCountryTag,
           product.countriesTags?.contains(preferredCountryTag) == true {
            score += 280
        }

        score += max(0, 40 - originalIndex)

        return score
    }

    private func normalizeSearchText(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let cleaned = folded.replacingOccurrences(
            of: #"[^\p{L}\p{N}]+"#,
            with: " ",
            options: .regularExpression
        )

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct SearchLocaleContext {
        let preferredLanguageCodes: [String]
        let preferredCountryTag: String?

        static var current: SearchLocaleContext {
            let preferredLanguageCodes = orderedUnique(
                Locale.preferredLanguages.compactMap(Self.languageCode(from:)) + ["en"]
            )
            let preferredCountryTag = Locale.autoupdatingCurrent.regionCode.flatMap(Self.countryTag(from:))

            return SearchLocaleContext(
                preferredLanguageCodes: preferredLanguageCodes,
                preferredCountryTag: preferredCountryTag
            )
        }

        private static func orderedUnique(_ values: [String]) -> [String] {
            var seen = Set<String>()

            return values.compactMap { value in
                let normalized = value.lowercased()
                guard seen.insert(normalized).inserted else { return nil }
                return normalized
            }
        }

        private static func languageCode(from identifier: String) -> String? {
            identifier
                .split(whereSeparator: { $0 == "-" || $0 == "_" })
                .first?
                .lowercased()
        }

        private static func countryTag(from regionCode: String) -> String? {
            let englishLocale = Locale(identifier: "en_US_POSIX")

            guard let localizedRegionName = englishLocale.localizedString(forRegionCode: regionCode) else {
                return nil
            }

            let slug = localizedRegionName
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: englishLocale)
                .replacingOccurrences(of: "&", with: " and ")
                .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

            guard !slug.isEmpty else { return nil }

            return "en:\(slug)"
        }
    }

    func createFoodItem(from product: OpenFoodFactsProduct) -> FoodItem {
        let nutriments = product.nutriments
        let portions = Self.buildPortionOptions(
            servingSize: product.servingSize,
            servingQuantityG: product.servingQuantityG
        )
        return FoodItem(
            name: product.productName ?? "Unknown",
            brand: product.brands,
            barcode: product.code,
            caloriesPer100g: nutriments?.energyKcal100g ?? 0,
            proteinPer100g: nutriments?.proteins100g ?? 0,
            carbsPer100g: nutriments?.carbohydrates100g ?? 0,
            fatPer100g: nutriments?.fat100g ?? 0,
            defaultServingG: product.servingQuantityG,
            servingDescription: product.servingSize,
            portionOptions: portions
        )
    }

    static func buildPortionOptions(servingSize: String?, servingQuantityG: Double?) -> [PortionOption] {
        guard let grams = servingQuantityG, grams > 0 else { return [] }

        let name = parsePortionName(from: servingSize)
        return [PortionOption(name: name, gramsPerPortion: grams)]
    }

    private static func parsePortionName(from servingSize: String?) -> String {
        guard let raw = servingSize?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
            return "serving"
        }

        let lowered = raw.lowercased()

        let portionKeywords = [
            "piece", "slice", "cup", "tbsp", "tablespoon",
            "tsp", "teaspoon", "scoop", "bar", "can",
            "bottle", "packet", "pouch", "container",
            "bowl", "sandwich", "wrap", "roll", "biscuit",
            "cookie", "cracker", "wafer", "stick", "unit",
        ]

        for keyword in portionKeywords {
            if lowered.contains(keyword) {
                return keyword
            }
        }

        let quantityPattern = #"^\d+[\.,]?\d*\s*(?:g|ml|oz|fl)"#
        if lowered.range(of: quantityPattern, options: .regularExpression) != nil {
            return "serving"
        }

        let parentheticalPattern = #"^([^(]+)\s*\("#
        if let match = raw.range(of: parentheticalPattern, options: .regularExpression) {
            let extracted = String(raw[match]).trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "("))
                .trimmingCharacters(in: .whitespaces)
            if !extracted.isEmpty, Double(extracted) == nil {
                return extracted.lowercased()
            }
        }

        return "serving"
    }
}

// MARK: - API Response Models

struct SearchResponse: Decodable {
    let hits: [OpenFoodFactsProduct]
}

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
    let lang: String?
    let countriesTags: [String]?

    var id: String { code ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantityG = "serving_quantity"
        case nutriments
        case lang
        case countriesTags = "countries_tags"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)
        servingQuantityG = try container.decodeIfPresent(Double.self, forKey: .servingQuantityG)
        nutriments = try container.decodeIfPresent(OFFNutriments.self, forKey: .nutriments)
        lang = try container.decodeIfPresent(String.self, forKey: .lang)
        countriesTags = try container.decodeIfPresent([String].self, forKey: .countriesTags)

        // search-a-licious returns brands as [String], the main API returns String
        if let brandsString = try? container.decodeIfPresent(String.self, forKey: .brands) {
            brands = brandsString
        } else if let brandsArray = try? container.decodeIfPresent([String].self, forKey: .brands) {
            brands = brandsArray.joined(separator: ", ")
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
