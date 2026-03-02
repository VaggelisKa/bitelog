import SwiftUI
import SwiftData

struct FoodSearchView: View {
    let mealType: MealType
    let logDate: Date
    var snackIndex: Int = 0

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodItem.lastUsed, order: .reverse) private var recentFoods: [FoodItem]

    @State private var searchService = FoodSearchService()
    @State private var searchText = ""
    @State private var selectedProduct: OpenFoodFactsProduct?
    @State private var selectedFoodItem: FoodItem?
    @State private var shouldDismissAfterLog = false
    @FocusState private var isSearchFocused: Bool

    private var showingRecent: Bool {
        searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var displayedRecentFoods: [FoodItem] {
        Array(recentFoods.prefix(20))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if showingRecent {
                    recentFoodsList
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedProduct, onDismiss: dismissIfNeeded) { product in
                let food = searchService.createFoodItem(from: product)
                PortionPickerView(
                    foodItem: food,
                    mealType: mealType,
                    logDate: logDate,
                    isNewFood: true,
                    snackIndex: snackIndex
                ) { shouldDismissAfterLog = true }
            }
            .sheet(item: $selectedFoodItem, onDismiss: dismissIfNeeded) { food in
                PortionPickerView(
                    foodItem: food,
                    mealType: mealType,
                    logDate: logDate,
                    isNewFood: false,
                    snackIndex: snackIndex
                ) { shouldDismissAfterLog = true }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(BiteLogTheme.textSecondary)

            TextField("Search foods...", text: $searchText)
                .font(BiteLogTheme.bodyText)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { searchService.search(query: searchText) }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchService.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(BiteLogTheme.textSecondary)
                }
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, BiteLogTheme.pagePadding)
        .padding(.vertical, 10)
        .onChange(of: searchText) {
            searchService.search(query: searchText)
        }
    }

    private var recentFoodsList: some View {
        Group {
            if displayedRecentFoods.isEmpty {
                ContentUnavailableView(
                    "No Recent Foods",
                    systemImage: "clock",
                    description: Text("Search above to find and log food.")
                )
            } else {
                List {
                    Section {
                        ForEach(displayedRecentFoods) { food in
                            FoodRowView(
                                name: food.name,
                                brand: food.brand,
                                caloriesPer100g: food.caloriesPer100g
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFoodItem = food
                            }
                        }
                    } header: {
                        Text("Recent")
                            .font(BiteLogTheme.caption)
                            .foregroundStyle(BiteLogTheme.textSecondary)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var searchResultsList: some View {
        Group {
            if searchService.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = searchService.errorMessage {
                ContentUnavailableView(
                    "Search Error",
                    systemImage: "wifi.exclamationmark",
                    description: Text(error)
                )
            } else if searchService.searchResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term.")
                )
            } else {
                List {
                    ForEach(searchService.searchResults) { product in
                        FoodRowView(
                            name: product.productName ?? "Unknown",
                            brand: product.brands,
                            caloriesPer100g: product.nutriments?.energyKcal100g ?? 0
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProduct = product
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func dismissIfNeeded() {
        if shouldDismissAfterLog {
            shouldDismissAfterLog = false
            dismiss()
        }
    }
}
