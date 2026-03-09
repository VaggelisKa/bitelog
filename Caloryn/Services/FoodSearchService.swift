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
        "nutrition_grades",
        "lang",
        "countries_tags"
    ].joined(separator: ",")
    private static let globalPageSize = 60
    private static let countryPageSize = 24

    private func performSearch(query: String) async throws -> [OpenFoodFactsProduct] {
        let localeContext = SearchLocaleContext.current

        async let globalTask = fetchGlobalResults(query: query, localeContext: localeContext)
        async let countryTask = fetchCountryResults(query: query, localeContext: localeContext)

        let globalResults = (try? await globalTask) ?? []
        let countryResults = (try? await countryTask) ?? []

        let countryProductCodes = Set(countryResults.compactMap(\.code))
        let merged = mergeResults(primary: countryResults, secondary: globalResults)

        return rankResults(merged, for: query, localeContext: localeContext, countrySearchCodes: countryProductCodes)
    }

    private func fetchGlobalResults(
        query: String,
        localeContext: SearchLocaleContext
    ) async throws -> [OpenFoodFactsProduct] {
        var components = URLComponents(string: "\(Self.searchBaseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: Self.searchFields),
            URLQueryItem(name: "page_size", value: String(Self.globalPageSize)),
            URLQueryItem(name: "langs", value: localeContext.preferredLanguageCodes.joined(separator: ","))
        ]

        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        return response.hits.filter { $0.productName != nil && $0.nutriments?.energyKcal100g != nil }
    }

    private func fetchCountryResults(
        query: String,
        localeContext: SearchLocaleContext
    ) async throws -> [OpenFoodFactsProduct] {
        guard let countryTag = localeContext.preferredCountryTag else { return [] }

        var components = URLComponents(string: "\(Self.baseURL)/cgi/search.pl")
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "tagtype_0", value: "countries"),
            URLQueryItem(name: "tag_contains_0", value: "contains"),
            URLQueryItem(name: "tag_0", value: countryTag),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: String(Self.countryPageSize)),
            URLQueryItem(name: "fields", value: Self.searchFields)
        ]

        guard let url = components?.url else { return [] }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicSearchResponse.self, from: data)

        return response.products.filter { $0.productName != nil && $0.nutriments?.energyKcal100g != nil }
    }

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

    private func rankResults(
        _ products: [OpenFoodFactsProduct],
        for query: String,
        localeContext: SearchLocaleContext,
        countrySearchCodes: Set<String>
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
                    originalIndex: lhs.offset,
                    isFromCountrySearch: lhs.element.code.map { countrySearchCodes.contains($0) } ?? false
                )
                let rightScore = score(
                    rhs.element,
                    normalizedQuery: normalizedQuery,
                    queryTokens: queryTokens,
                    localeContext: localeContext,
                    originalIndex: rhs.offset,
                    isFromCountrySearch: rhs.element.code.map { countrySearchCodes.contains($0) } ?? false
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
        originalIndex: Int,
        isFromCountrySearch: Bool
    ) -> Int {
        let normalizedName = normalizeSearchText(product.productName ?? "")
        let normalizedBrand = normalizeSearchText(product.brands ?? "")
        let nameWords = Set(normalizedName.split(separator: " ").map(String.init))
        let brandWords = Set(normalizedBrand.split(separator: " ").map(String.init))
        let allWords = nameWords.union(brandWords)
        let productLanguage = product.lang?.lowercased()

        var s = 0

        guard !normalizedQuery.isEmpty else { return s }

        // --- Full-query matching against product name ---
        if normalizedName == normalizedQuery {
            s += 1_500
        } else if normalizedName.hasPrefix(normalizedQuery) {
            s += 1_000
        } else if normalizedName.contains(normalizedQuery) {
            s += 750
        }

        // --- Full-query matching against brand ---
        if normalizedBrand == normalizedQuery {
            s += 350
        } else if normalizedBrand.contains(normalizedQuery) {
            s += 200
        }

        // --- All-tokens-match bonus ---
        // Strong signal when every query word appears somewhere in name+brand.
        if queryTokens.count > 1 {
            let allMatch = queryTokens.allSatisfy { token in
                allWords.contains { $0.hasPrefix(token) || token.hasPrefix($0) }
            }
            if allMatch { s += 400 }
        }

        // --- Per-token scoring with word-boundary awareness ---
        var nameTokenHits = 0
        var brandTokenHits = 0
        for token in queryTokens where !token.isEmpty {
            let nameWordHit = nameWords.contains { $0.hasPrefix(token) || $0 == token }
            if nameWordHit {
                s += 150
                nameTokenHits += 1
            } else if normalizedName.contains(token) {
                s += 70
                nameTokenHits += 1
            }

            let brandWordHit = brandWords.contains { $0.hasPrefix(token) || $0 == token }
            if brandWordHit {
                s += 60
                brandTokenHits += 1
            } else if normalizedBrand.contains(token) {
                s += 25
                brandTokenHits += 1
            }
        }

        // Cross-match bonus: tokens split across brand and name (e.g. "Arla Skyr")
        if nameTokenHits > 0 && brandTokenHits > 0 && queryTokens.count > 1 {
            s += 300
        }

        // --- Language ---
        if let productLanguage {
            if localeContext.preferredLanguageCodes.first == productLanguage {
                s += 400
            } else if localeContext.preferredLanguageCodes.contains(productLanguage) {
                s += 250
            }
        }

        // --- Country (heavily boosted) ---
        var countryMatch = false
        if let preferredCountryTag = localeContext.preferredCountryTag,
           product.countriesTags?.contains(preferredCountryTag) == true {
            s += 600
            countryMatch = true
        }

        // Compound bonus when both country and primary language match
        if countryMatch, let productLanguage,
           localeContext.preferredLanguageCodes.first == productLanguage {
            s += 150
        }

        // Products returned by the country-scoped search get an extra nudge
        if isFromCountrySearch {
            s += 200
        }

        // --- Data quality signals ---
        if product.servingQuantityG != nil || product.servingSize != nil {
            s += 50
        }
        if product.nutritionGrades != nil {
            s += 35
        }
        if product.brands != nil, !product.brands!.isEmpty {
            s += 25
        }

        // --- Original API relevance ---
        s += max(0, 50 - originalIndex)

        return s
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

    private static func validNutriscoreGrade(_ raw: String?) -> String? {
        guard let letter = raw?.lowercased(), ["a", "b", "c", "d", "e"].contains(letter) else { return nil }
        return letter
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
            servingDescription: product.servingSize,
            nutriscoreGrade: Self.validNutriscoreGrade(product.nutritionGrades)
        )
    }
}

// MARK: - API Response Models

struct SearchResponse: Decodable {
    let hits: [OpenFoodFactsProduct]
}

struct ClassicSearchResponse: Decodable {
    let products: [OpenFoodFactsProduct]
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
    let nutritionGrades: String?
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
        case nutritionGrades = "nutrition_grades"
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
        nutritionGrades = try container.decodeIfPresent(String.self, forKey: .nutritionGrades)
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
