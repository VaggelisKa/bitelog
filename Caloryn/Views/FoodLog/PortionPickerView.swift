import SwiftUI
import SwiftData

struct PortionPickerView: View {
    let foodItem: FoodItem
    let mealType: MealType
    let logDate: Date
    let isNewFood: Bool
    let snackIndex: Int
    var onLogged: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var portionGrams: Double = 100
    @State private var selectedMeal: MealType
    @State private var showingCustomFoodEditor = false
    @State private var showingRecipeEditor = false
    @State private var portionMode: PortionMode = .grams
    @State private var selectedGramStep: Int = 100
    @State private var selectedServingCount: Int = 1
    @State private var selectedRecipeServingID = RecipeServingOption.one.id

    private enum PortionMode: Hashable {
        case grams
        case serving
        case recipeServing
    }

    private struct RecipeServingOption: Identifiable, Hashable {
        let id: String
        let label: String
        let multiplier: Double

        static let one = RecipeServingOption(id: "1", label: "1", multiplier: 1)
    }

    private static let recipeServingOptions: [RecipeServingOption] = [
        RecipeServingOption(id: "quarter", label: "1/4", multiplier: 0.25),
        RecipeServingOption(id: "half", label: "1/2", multiplier: 0.5),
        .one,
        RecipeServingOption(id: "2", label: "2", multiplier: 2),
        RecipeServingOption(id: "3", label: "3", multiplier: 3),
        RecipeServingOption(id: "4", label: "4", multiplier: 4)
    ]

    init(foodItem: FoodItem, mealType: MealType, logDate: Date, isNewFood: Bool, snackIndex: Int = 0, onLogged: (() -> Void)? = nil) {
        self.foodItem = foodItem
        self.mealType = mealType
        self.logDate = logDate
        self.isNewFood = isNewFood
        self.snackIndex = snackIndex
        self.onLogged = onLogged
        self._selectedMeal = State(initialValue: mealType)

        let defaultPortion = foodItem.isRecipe ? 100 : (foodItem.defaultServingG ?? 100)
        self._portionGrams = State(initialValue: defaultPortion)

        let nearestStep = Self.normalizedGramStep(defaultPortion, limit: Self.gramOptionLimit(for: foodItem))
        self._selectedGramStep = State(initialValue: nearestStep)

        if foodItem.isRecipe {
            self._portionMode = State(initialValue: .grams)
            self._selectedRecipeServingID = State(initialValue: Self.nearestRecipeServingOptionID(for: defaultPortion, recipeTotalGrams: foodItem.defaultServingG ?? 100))
        } else if foodItem.servingInfo != nil {
            self._portionMode = State(initialValue: .serving)
            self._selectedServingCount = State(initialValue: 1)
        }
    }

    private var previewCalories: Double { foodItem.calories(forGrams: portionGrams) }
    private var previewProtein: Double { foodItem.protein(forGrams: portionGrams) }
    private var previewCarbs: Double { foodItem.carbs(forGrams: portionGrams) }
    private var previewFat: Double { foodItem.fat(forGrams: portionGrams) }

    private var recipeTotalGrams: Double {
        foodItem.defaultServingG ?? 100
    }

    private var gramOptions: [Int] {
        Array(stride(from: 5, through: Self.gramOptionLimit(for: foodItem), by: 5))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                foodHeader

                caloriePreview

                portionPicker

                macroPreview

                mealSelector
            }
            .padding(.horizontal, CalorynTheme.pagePadding)
            .padding(.bottom, 100)
        }
        .navigationTitle("Portion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if foodItem.isCustom || foodItem.isRecipe {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if foodItem.isRecipe {
                            showingRecipeEditor = true
                        } else {
                            showingCustomFoodEditor = true
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CalorynTheme.sage)
                    }
                    .accessibilityLabel(foodItem.isRecipe ? "Edit Recipe" : "Edit Custom Food")
                }
            }
        }
        .sheet(isPresented: $showingCustomFoodEditor) {
            CustomFoodFormView(
                existingFood: foodItem,
                onSaved: { _ in
                    updatePortionFromDefaultServing()
                },
                allowsDeletion: false
            )
        }
        .sheet(isPresented: $showingRecipeEditor) {
            RecipeFormView(
                existingRecipe: foodItem,
                onSaved: { _ in
                    updatePortionFromDefaultServing()
                },
                allowsDeletion: false
            )
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: logFood) {
                Text(foodItem.isRecipe ? "Log Recipe" : "Log Food")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .tint(CalorynTheme.sage)
            .padding(.horizontal, CalorynTheme.pagePadding)
            .padding(.bottom, 16)
        }
    }

    @AppStorage("showNutriscore") private var showNutriscore = true

    private var foodHeader: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text(foodItem.name)
                    .font(CalorynTheme.sectionTitle)
                    .foregroundStyle(CalorynTheme.textPrimary)
                    .multilineTextAlignment(.center)

                if showNutriscore, let grade = foodItem.nutriscoreGrade {
                    NutriscoreBadge(grade: grade)
                }
            }

            if let brand = foodItem.brand, !brand.isEmpty {
                Text(brand)
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }

            if !foodItem.isRecipe, let serving = foodItem.servingDescription, !serving.isEmpty {
                Text("Serving: \(serving)")
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }
        }
        .padding(.top, 8)
    }

    private var caloriePreview: some View {
        VStack(spacing: 4) {
            Text("\(Int(previewCalories))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(CalorynTheme.sage)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.3), value: Int(previewCalories))

            Text("calories")
                .font(CalorynTheme.bodyText)
                .foregroundStyle(CalorynTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }

    private var maxServingCount: Int {
        guard let info = foodItem.servingInfo else { return 1 }
        return max(2, min(10, Int(500 / info.gramsPerUnit)))
    }

    private var portionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PORTION SIZE")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            HStack(spacing: 0) {
                Group {
                    switch portionMode {
                    case .grams:
                        Picker("Amount", selection: $selectedGramStep) {
                            ForEach(gramOptions, id: \.self) { g in
                                Text("\(g)").tag(g)
                            }
                        }
                    case .serving:
                        Picker("Count", selection: $selectedServingCount) {
                            ForEach(1...maxServingCount, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                    case .recipeServing:
                        Picker("Recipe serving", selection: $selectedRecipeServingID) {
                            ForEach(Self.recipeServingOptions) { option in
                                Text(option.label).tag(option.id)
                            }
                        }
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                if foodItem.isRecipe {
                    Picker("Unit", selection: $portionMode) {
                        Text("grams").tag(PortionMode.grams)
                        Text("serving").tag(PortionMode.recipeServing)
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                } else if let info = foodItem.servingInfo {
                    Picker("Unit", selection: $portionMode) {
                        Text("grams").tag(PortionMode.grams)
                        Text(info.unitName).tag(PortionMode.serving)
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                } else {
                    Text("grams")
                        .font(CalorynTheme.bodyText)
                        .foregroundStyle(CalorynTheme.textSecondary)
                        .frame(width: 120)
                }
            }
            .frame(height: 150)
            .clipped()
            .onChange(of: selectedGramStep) {
                guard portionMode == .grams else { return }
                portionGrams = Double(selectedGramStep)
                if foodItem.isRecipe {
                    selectedRecipeServingID = nearestRecipeServingOptionID(for: portionGrams)
                }
            }
            .onChange(of: selectedServingCount) {
                guard portionMode == .serving, let info = foodItem.servingInfo else { return }
                let grams = Double(selectedServingCount) * info.gramsPerUnit
                portionGrams = grams
            }
            .onChange(of: selectedRecipeServingID) {
                guard portionMode == .recipeServing, let option = selectedRecipeServingOption else { return }
                portionGrams = recipeTotalGrams * option.multiplier
                selectedGramStep = Self.normalizedGramStep(portionGrams, limit: Self.gramOptionLimit(for: foodItem))
            }
            .onChange(of: portionMode) {
                switch portionMode {
                case .grams:
                    let nearest = Self.normalizedGramStep(portionGrams, limit: Self.gramOptionLimit(for: foodItem))
                    selectedGramStep = nearest
                    portionGrams = Double(nearest)
                case .serving:
                    guard let info = foodItem.servingInfo else { return }
                    let count = max(1, min(maxServingCount, Int(round(portionGrams / info.gramsPerUnit))))
                    selectedServingCount = count
                    let grams = Double(count) * info.gramsPerUnit
                    portionGrams = grams
                case .recipeServing:
                    selectedRecipeServingID = nearestRecipeServingOptionID(for: portionGrams)
                    if let option = selectedRecipeServingOption {
                        portionGrams = recipeTotalGrams * option.multiplier
                    }
                }
            }
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private var macroPreview: some View {
        HStack(spacing: CalorynTheme.cardSpacing) {
            macroPill("Protein", value: previewProtein, color: CalorynTheme.proteinColor)
            macroPill("Carbs", value: previewCarbs, color: CalorynTheme.carbColor)
            macroPill("Fat", value: previewFat, color: CalorynTheme.fatColor)
        }
    }

    private func macroPill(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)
            Text(value.macroFormatted)
                .font(CalorynTheme.numericBody)
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.3), value: value.macroFormatted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private var mealSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEAL")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            Picker("Meal", selection: $selectedMeal) {
                ForEach(MealType.allCases) { meal in
                    Label(meal.displayName, systemImage: meal.iconName)
                        .tag(meal)
                }
            }
            .pickerStyle(.segmented)
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private func logFood() {
        let food: FoodItem
        if isNewFood {
            food = foodItem
            modelContext.insert(food)
        } else {
            food = foodItem
        }
        food.lastUsed = Date()

        let entry = FoodLogEntry(
            date: logDate,
            mealType: selectedMeal,
            foodItem: food,
            portionGrams: portionGrams,
            snackIndex: selectedMeal == .snack ? snackIndex : 0
        )
        modelContext.insert(entry)
        if let onLogged {
            onLogged()
        } else {
            dismiss()
        }
    }

    private func updatePortionFromDefaultServing() {
        let defaultPortion = foodItem.isRecipe ? 100 : (foodItem.defaultServingG ?? 100)
        portionGrams = defaultPortion
        selectedGramStep = Self.normalizedGramStep(defaultPortion, limit: Self.gramOptionLimit(for: foodItem))
        selectedRecipeServingID = nearestRecipeServingOptionID(for: defaultPortion)

        if foodItem.isRecipe {
            portionMode = .grams
        } else if let info = foodItem.servingInfo {
            portionMode = .serving
            let count = max(1, min(maxServingCount, Int(round(defaultPortion / info.gramsPerUnit))))
            selectedServingCount = count
        }
    }

    private var selectedRecipeServingOption: RecipeServingOption? {
        Self.recipeServingOptions.first { $0.id == selectedRecipeServingID }
    }

    private func nearestRecipeServingOptionID(for grams: Double) -> String {
        Self.nearestRecipeServingOptionID(for: grams, recipeTotalGrams: recipeTotalGrams)
    }

    private static func nearestRecipeServingOptionID(for grams: Double, recipeTotalGrams: Double) -> String {
        guard recipeTotalGrams > 0 else { return RecipeServingOption.one.id }
        let multiplier = grams / recipeTotalGrams
        return recipeServingOptions.min {
            abs($0.multiplier - multiplier) < abs($1.multiplier - multiplier)
        }?.id ?? RecipeServingOption.one.id
    }

    private static func gramOptionLimit(for foodItem: FoodItem) -> Int {
        let defaultServing = foodItem.defaultServingG ?? 100
        let recipeLimit = Int(ceil(defaultServing / 5) * 5)
        if foodItem.isRecipe {
            let maxServingMultiplier = recipeServingOptions.map(\.multiplier).max() ?? 1
            let servingLimit = Int(ceil(defaultServing * maxServingMultiplier / 5) * 5)
            return max(500, servingLimit)
        }
        return max(500, recipeLimit)
    }

    private static func normalizedGramStep(_ grams: Double, limit: Int) -> Int {
        max(5, min(limit, Int(round(grams / 5)) * 5))
    }
}

#Preview("Cup serving") {
    let food = FoodItem(
        name: "Skyr",
        brand: "Arla",
        caloriesPer100g: 63,
        proteinPer100g: 11,
        carbsPer100g: 4,
        fatPer100g: 0,
        defaultServingG: 170,
        servingDescription: "1 cup (170g)"
    )
    return NavigationStack {
        PortionPickerView(
            foodItem: food,
            mealType: .lunch,
            logDate: .now,
            isNewFood: true
        )
    }
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self, RecipeIngredient.self], inMemory: true)
}

#Preview("Slice serving") {
    let food = FoodItem(
        name: "Rugbroed",
        brand: "Schulstad",
        caloriesPer100g: 210,
        proteinPer100g: 7,
        carbsPer100g: 36,
        fatPer100g: 2,
        defaultServingG: 45,
        servingDescription: "1 slice (45g)"
    )
    return PortionPickerView(
        foodItem: food,
        mealType: .lunch,
        logDate: .now,
        isNewFood: true
    )
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self, RecipeIngredient.self], inMemory: true)
}

#Preview("No serving info") {
    let food = FoodItem(
        name: "Olive Oil",
        brand: "Filippo Berio",
        caloriesPer100g: 884,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 100
    )
    return PortionPickerView(
        foodItem: food,
        mealType: .dinner,
        logDate: .now,
        isNewFood: true
    )
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self, RecipeIngredient.self], inMemory: true)
}
