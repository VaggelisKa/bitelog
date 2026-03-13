import SwiftUI
import SwiftData
import UIKit

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
    @State private var showingScanner = false
    @State private var showingCustomFoodForm = false
    @State private var editingCustomFood: FoodItem?
    @State private var isLookingUpBarcode = false
    @State private var barcodeLookupError: String?
    @FocusState private var isSearchFocused: Bool

    private var showingRecent: Bool {
        searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var customFoods: [FoodItem] {
        recentFoods.filter { $0.isCustom }
    }

    private var displayedRecentFoods: [FoodItem] {
        Array(recentFoods.filter { !$0.isCustom }.prefix(20))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if isLookingUpBarcode || barcodeLookupError != nil {
                    barcodeLookupOverlay
                } else if showingRecent {
                    recentFoodsList
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCustomFoodForm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CalorynTheme.sage)
                    }
                    .accessibilityLabel("Create Custom Food")
                }
            }
            .navigationDestination(item: $selectedProduct) { product in
                let food = searchService.createFoodItem(from: product)
                PortionPickerView(
                    foodItem: food,
                    mealType: mealType,
                    logDate: logDate,
                    isNewFood: true,
                    snackIndex: snackIndex
                ) { dismiss() }
            }
            .navigationDestination(item: $selectedFoodItem) { food in
                PortionPickerView(
                    foodItem: food,
                    mealType: mealType,
                    logDate: logDate,
                    isNewFood: false,
                    snackIndex: snackIndex
                ) { dismiss() }
            }
            .sheet(isPresented: $showingCustomFoodForm) {
                CustomFoodFormView(onSaved: { food in
                    showingCustomFoodForm = false
                    Task { @MainActor in
                        selectedFoodItem = food
                    }
                })
            }
            .sheet(item: $editingCustomFood) { food in
                CustomFoodFormView(existingFood: food)
            }
            .fullScreenCover(isPresented: $showingScanner) {
                barcodeScannerSheet
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CalorynTheme.textSecondary)

                TextField("Search foods...", text: $searchText)
                    .font(CalorynTheme.bodyText)
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
                            .foregroundStyle(CalorynTheme.textSecondary)
                    }
                }
            }
            .padding(12)
            .glassEffect(.regular, in: .capsule)

            Button {
                isSearchFocused = false
                showingScanner = true
            } label: {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(CalorynTheme.sage)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.horizontal, CalorynTheme.pagePadding)
        .padding(.vertical, 10)
        .onChange(of: searchText) {
            searchService.search(query: searchText)
        }
    }

    private var recentFoodsList: some View {
        Group {
            if displayedRecentFoods.isEmpty && customFoods.isEmpty {
                ContentUnavailableView(
                    "No Recent Foods",
                    systemImage: "clock",
                    description: Text("Search above or tap + to create a custom food.")
                )
            } else {
                List {
                    if !customFoods.isEmpty {
                        Section {
                            ForEach(customFoods) { food in
                                customFoodRow(for: food)
                            }
                        } header: {
                            Text("My Foods")
                                .font(CalorynTheme.caption)
                                .foregroundStyle(CalorynTheme.textSecondary)
                        }
                    }

                    if !displayedRecentFoods.isEmpty {
                        Section {
                            ForEach(displayedRecentFoods) { food in
                                FoodRowView(
                                    name: food.name,
                                    brand: food.brand,
                                    caloriesPer100g: food.caloriesPer100g,
                                    nutriscoreGrade: food.nutriscoreGrade,
                                    servingDescription: food.servingDescription
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedFoodItem = food
                                }
                            }
                        } header: {
                            Text("Recent")
                                .font(CalorynTheme.caption)
                                .foregroundStyle(CalorynTheme.textSecondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var matchingCustomFoods: [FoodItem] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return customFoods.filter {
            $0.name.lowercased().contains(query)
            || ($0.brand?.lowercased().contains(query) ?? false)
        }
    }

    private var searchResultsList: some View {
        Group {
            if searchService.isSearching && matchingCustomFoods.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = searchService.errorMessage, matchingCustomFoods.isEmpty {
                ContentUnavailableView(
                    "Search Error",
                    systemImage: "wifi.exclamationmark",
                    description: Text(error)
                )
            } else if searchService.searchResults.isEmpty && matchingCustomFoods.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term.")
                )
            } else {
                List {
                    if !matchingCustomFoods.isEmpty {
                        Section {
                            ForEach(matchingCustomFoods) { food in
                                customFoodRow(for: food)
                            }
                        } header: {
                            Text("My Foods")
                                .font(CalorynTheme.caption)
                                .foregroundStyle(CalorynTheme.textSecondary)
                        }
                    }

                    if !searchService.searchResults.isEmpty {
                        Section {
                            ForEach(searchService.searchResults) { product in
                                FoodRowView(
                                    name: product.productName ?? "Unknown",
                                    brand: product.brands,
                                    caloriesPer100g: product.nutriments?.energyKcal100g ?? 0,
                                    nutriscoreGrade: product.nutritionGrades.flatMap { g in ["a","b","c","d","e"].contains(g.lowercased()) ? g.lowercased() : nil },
                                    servingDescription: product.formattedServingDescription,
                                    caloriesPerServing: product.caloriesPerServing
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedProduct = product
                                }
                            }
                        } header: {
                            if !matchingCustomFoods.isEmpty {
                                Text("Search Results")
                                    .font(CalorynTheme.caption)
                                    .foregroundStyle(CalorynTheme.textSecondary)
                            }
                        }
                    }

                    if searchService.isSearching {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func customFoodRow(for food: FoodItem) -> some View {
        FoodRowView(
            name: food.name,
            brand: food.brand,
            caloriesPer100g: food.caloriesPer100g,
            nutriscoreGrade: food.nutriscoreGrade,
            servingDescription: food.servingDescription,
            isCustom: true
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedFoodItem = food
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(food)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                editingCustomFood = food
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(CalorynTheme.sage)
        }
    }

    private var barcodeScannerSheet: some View {
        ZStack(alignment: .topLeading) {
            BarcodeScannerView { code in
                showingScanner = false
                handleScannedBarcode(code)
            }
            .ignoresSafeArea()

            Button {
                showingScanner = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 56)
            .padding(.leading, 20)
        }
    }

    private var barcodeLookupOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            if let error = barcodeLookupError {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(CalorynTheme.textSecondary)
                Text(error)
                    .font(CalorynTheme.bodyText)
                    .foregroundStyle(CalorynTheme.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button("Dismiss") {
                        barcodeLookupError = nil
                    }
                    .buttonStyle(.bordered)
                    .tint(CalorynTheme.textSecondary)

                    Button("Try Again") {
                        barcodeLookupError = nil
                        showingScanner = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CalorynTheme.sage)
                }
            } else {
                ProgressView()
                    .controlSize(.large)
                Text("Looking up product...")
                    .font(CalorynTheme.bodyText)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func handleScannedBarcode(_ code: String) {
        isLookingUpBarcode = true
        barcodeLookupError = nil

        Task {
            do {
                let product = try await searchService.lookupBarcode(code)
                isLookingUpBarcode = false
                selectedProduct = product
            } catch is BarcodeLookupError {
                isLookingUpBarcode = false
                barcodeLookupError = "No results found\nfor this barcode."
                triggerBarcodeLookupHaptic(.warning)
            } catch {
                isLookingUpBarcode = false
                barcodeLookupError = "Lookup failed.\nCheck your connection."
                triggerBarcodeLookupHaptic(.error)
            }
        }
    }

    private func triggerBarcodeLookupHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

}

#Preview {
    FoodSearchView(mealType: .breakfast, logDate: .now)
        .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}
