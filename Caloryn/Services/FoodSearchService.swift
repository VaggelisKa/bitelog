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

            await performProgressiveSearch(query: trimmed)
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
    private static let globalPageSize = 24
    private static let countryPageSize = 24
    private static let minimumCountryResultsBeforeSkippingFallback = 8
    private static let minimumStrongCountryMatchesBeforeSkippingFallback = 5
    private static let strongNameMatchThreshold = 900

    private func performProgressiveSearch(query: String) async {
        let localeContext = SearchLocaleContext.current
        let normalizedQuery = normalizeSearchText(query)
        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)

        guard let countryQuery = buildCountryFilteredQuery(query: query, localeContext: localeContext) else {
            let globalResults = (try? await fetchGlobalResults(query: query, localeContext: localeContext)) ?? []
            guard !Task.isCancelled else { return }

            searchResults = rankResults(globalResults, for: query, localeContext: localeContext)
            isSearching = false
            return
        }

        let countryResults = (try? await fetchCountryResults(query: countryQuery, localeContext: localeContext)) ?? []
        guard !Task.isCancelled else { return }

        if !countryResults.isEmpty {
            searchResults = rankResults(countryResults, for: query, localeContext: localeContext)
        }

        let shouldFetchFallback = shouldFetchGlobalFallback(
            countryResults: countryResults,
            normalizedQuery: normalizedQuery,
            queryTokens: queryTokens
        )
        guard shouldFetchFallback else {
            isSearching = false
            return
        }

        let globalResults = (try? await fetchGlobalResults(query: query, localeContext: localeContext)) ?? []
        guard !Task.isCancelled else { return }

        let rankedCountryResults = rankResults(countryResults, for: query, localeContext: localeContext)
        let rankedGlobalResults = rankResults(globalResults, for: query, localeContext: localeContext)
        searchResults = mergeResults(primary: rankedCountryResults, secondary: rankedGlobalResults)
        isSearching = false
    }

    private func fetchGlobalResults(
        query: String,
        localeContext: SearchLocaleContext
    ) async throws -> [OpenFoodFactsProduct] {
        try await fetchSearchResults(
            query: query,
            pageSize: Self.globalPageSize,
            localeContext: localeContext
        )
    }

    private func fetchCountryResults(
        query: String,
        localeContext: SearchLocaleContext
    ) async throws -> [OpenFoodFactsProduct] {
        return try await fetchSearchResults(
            query: query,
            pageSize: Self.countryPageSize,
            localeContext: localeContext
        )
    }

    private func fetchSearchResults(
        query: String,
        pageSize: Int,
        localeContext: SearchLocaleContext
    ) async throws -> [OpenFoodFactsProduct] {
        var components = URLComponents(string: "\(Self.searchBaseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: Self.searchFields),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "langs", value: localeContext.preferredLanguageCodes.joined(separator: ","))
        ]

        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        return response.hits.filter { $0.productName != nil && $0.nutriments?.energyKcal100g != nil }
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
        let nameWords = Set(normalizedName.split(separator: " ").map(String.init))
        let brandWords = Set(normalizedBrand.split(separator: " ").map(String.init))
        let productLanguage = product.lang?.lowercased()

        var s = 0

        guard !normalizedQuery.isEmpty else { return s }

        // Country-vs-global ordering is decided before local scoring.
        // Inside each tier, product name should dominate brand matches.
        if normalizedName == normalizedQuery {
            s += 2_400
        } else if normalizedName.hasPrefix(normalizedQuery) {
            s += 1_800
        } else if normalizedName.contains(normalizedQuery) {
            s += 1_200
        }

        if normalizedBrand == normalizedQuery {
            s += 140
        } else if normalizedBrand.contains(normalizedQuery) {
            s += 80
        }

        if queryTokens.count > 1 {
            let allNameTokensMatch = queryTokens.allSatisfy { token in
                nameWords.contains { $0.hasPrefix(token) || token.hasPrefix($0) }
            }
            if allNameTokensMatch {
                s += 700
            } else {
                let allCombinedTokensMatch = queryTokens.allSatisfy { token in
                    nameWords.contains { $0.hasPrefix(token) || token.hasPrefix($0) }
                    || brandWords.contains { $0.hasPrefix(token) || token.hasPrefix($0) }
                }
                if allCombinedTokensMatch {
                    s += 220
                }
            }
        }

        var nameTokenHits = 0
        var brandTokenHits = 0
        for token in queryTokens where !token.isEmpty {
            let nameWordHit = nameWords.contains { $0.hasPrefix(token) || $0 == token }
            if nameWordHit {
                s += 220
                nameTokenHits += 1
            } else if normalizedName.contains(token) {
                s += 100
                nameTokenHits += 1
            }

            let brandWordHit = brandWords.contains { $0.hasPrefix(token) || $0 == token }
            if brandWordHit {
                s += 35
                brandTokenHits += 1
            } else if normalizedBrand.contains(token) {
                s += 15
                brandTokenHits += 1
            }
        }

        if nameTokenHits > 0 && brandTokenHits > 0 && queryTokens.count > 1 {
            s += 75
        }

        if let productLanguage {
            if localeContext.preferredLanguageCodes.first == productLanguage {
                s += 120
            } else if localeContext.preferredLanguageCodes.contains(productLanguage) {
                s += 60
            }
        }

        if product.servingQuantityG != nil || product.servingSize != nil {
            s += 25
        }
        if product.nutritionGrades != nil {
            s += 15
        }
        if product.brands != nil, !product.brands!.isEmpty {
            s += 10
        }

        s += max(0, 25 - originalIndex)

        return s
    }

    private func shouldFetchGlobalFallback(
        countryResults: [OpenFoodFactsProduct],
        normalizedQuery: String,
        queryTokens: [String]
    ) -> Bool {
        guard !countryResults.isEmpty else { return true }
        guard countryResults.count >= Self.minimumCountryResultsBeforeSkippingFallback else { return true }

        let strongMatchCount = countryResults.filter {
            nameMatchStrength(for: $0, normalizedQuery: normalizedQuery, queryTokens: queryTokens) >= Self.strongNameMatchThreshold
        }.count

        return strongMatchCount < Self.minimumStrongCountryMatchesBeforeSkippingFallback
    }

    private func nameMatchStrength(
        for product: OpenFoodFactsProduct,
        normalizedQuery: String,
        queryTokens: [String]
    ) -> Int {
        let normalizedName = normalizeSearchText(product.productName ?? "")
        let nameWords = Set(normalizedName.split(separator: " ").map(String.init))
        var score = 0

        guard !normalizedQuery.isEmpty else { return score }

        if normalizedName == normalizedQuery {
            score += 2_400
        } else if normalizedName.hasPrefix(normalizedQuery) {
            score += 1_800
        } else if normalizedName.contains(normalizedQuery) {
            score += 1_200
        }

        if queryTokens.count > 1 {
            let allNameTokensMatch = queryTokens.allSatisfy { token in
                nameWords.contains { $0.hasPrefix(token) || token.hasPrefix($0) }
            }
            if allNameTokensMatch {
                score += 700
            }
        }

        for token in queryTokens where !token.isEmpty {
            if nameWords.contains(where: { $0.hasPrefix(token) || $0 == token }) {
                score += 220
            } else if normalizedName.contains(token) {
                score += 100
            }
        }

        return score
    }

    private func buildCountryFilteredQuery(
        query: String,
        localeContext: SearchLocaleContext
    ) -> String? {
        guard
            let countryTag = localeContext.preferredCountryTag,
            let safeCountryTag = luceneSafeCountryTag(countryTag)
        else {
            return nil
        }

        let escapedQuery = escapeLuceneSearchText(query)
        guard !escapedQuery.isEmpty else { return nil }

        return #"countries_tags:"\#(safeCountryTag)" \#(escapedQuery)"#
    }

    private func luceneSafeCountryTag(_ countryTag: String) -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789:-")
        guard countryTag.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
            return nil
        }
        return countryTag
    }

    private func escapeLuceneSearchText(_ text: String) -> String {
        let reservedCharacters = Set(#"+-!(){}[]^"~*?:\/&|"#.map(\.self))
        var escaped = ""

        for character in text {
            if reservedCharacters.contains(character) {
                escaped.append("\\")
            }
            escaped.append(character)
        }

        return escaped
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
