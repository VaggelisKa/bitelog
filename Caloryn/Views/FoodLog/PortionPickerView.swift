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
    @State private var portionText: String = "100"
    @State private var selectedMeal: MealType
    @State private var showingCustomFoodEditor = false

    @ScaledMetric private var quickButtonPadding: CGFloat = 10

    private let quickPortions: [(label: String, grams: Double)] = [
        ("50g", 50),
        ("100g", 100),
        ("150g", 150),
        ("200g", 200),
    ]

    init(foodItem: FoodItem, mealType: MealType, logDate: Date, isNewFood: Bool, snackIndex: Int = 0, onLogged: (() -> Void)? = nil) {
        self.foodItem = foodItem
        self.mealType = mealType
        self.logDate = logDate
        self.isNewFood = isNewFood
        self.snackIndex = snackIndex
        self.onLogged = onLogged
        self._selectedMeal = State(initialValue: mealType)
        let defaultPortion = foodItem.defaultServingG ?? 100
        self._portionGrams = State(initialValue: defaultPortion)
        self._portionText = State(initialValue: "\(Int(defaultPortion))")
    }

    private var previewCalories: Double { foodItem.calories(forGrams: portionGrams) }
    private var previewProtein: Double { foodItem.protein(forGrams: portionGrams) }
    private var previewCarbs: Double { foodItem.carbs(forGrams: portionGrams) }
    private var previewFat: Double { foodItem.fat(forGrams: portionGrams) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    foodHeader

                    caloriePreview

                    servingPicker

                    portionInput

                    macroPreview

                    mealSelector
                }
                .padding(.horizontal, CalorynTheme.pagePadding)
                .padding(.bottom, 100)
            }
            .navigationTitle("Portion")
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
                if foodItem.isCustom {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingCustomFoodEditor = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(CalorynTheme.sage)
                        }
                        .accessibilityLabel("Edit Custom Food")
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
            .safeAreaInset(edge: .bottom) {
                Button(action: logFood) {
                    Text("Log Food")
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
        .presentationDetents([.large])
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

            if let serving = foodItem.servingDescription, !serving.isEmpty {
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

    @ViewBuilder
    private var servingPicker: some View {
        if let info = foodItem.servingInfo {
            let maxCount = max(2, min(5, Int(500 / info.gramsPerUnit)))

            VStack(alignment: .leading, spacing: 12) {
                Text("SERVINGS")
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)

                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(1...maxCount, id: \.self) { count in
                            let grams = Double(count) * info.gramsPerUnit
                            let isSelected = abs(portionGrams - grams) < 0.5
                            Button {
                                withAnimation(.smooth(duration: 0.2)) {
                                    portionGrams = grams
                                    portionText = "\(Int(grams))"
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Text(info.label(for: count))
                                        .font(CalorynTheme.numericCaption)
                                    Text("\(Int(grams))g")
                                        .font(.system(size: 10, design: .rounded))
                                        .opacity(0.7)
                                }
                                .foregroundStyle(isSelected ? CalorynTheme.warmWhite : CalorynTheme.textPrimary)
                                .padding(.horizontal, quickButtonPadding)
                                .padding(.vertical, 8)
                                .lineLimit(1)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(
                                isSelected
                                    ? .regular.tint(CalorynTheme.sage).interactive()
                                    : .regular.interactive(),
                                in: .capsule
                            )
                        }
                    }
                }
            }
            .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
        }
    }

    private var portionInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PORTION SIZE")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            HStack {
                TextField("Grams", text: $portionText)
                    .font(CalorynTheme.numericBody)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: portionText) {
                        if let value = Double(portionText), value > 0 {
                            portionGrams = value
                        }
                    }

                Text("grams")
                    .font(CalorynTheme.bodyText)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }

            Slider(value: $portionGrams, in: 1...500, step: 1)
                .tint(CalorynTheme.sage)
                .onChange(of: portionGrams) {
                    portionText = "\(Int(portionGrams))"
                }

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(quickPortions, id: \.grams) { portion in
                        let isSelected = portionGrams == portion.grams
                        Button {
                            withAnimation(.smooth(duration: 0.2)) {
                                portionGrams = portion.grams
                                portionText = "\(Int(portion.grams))"
                            }
                        } label: {
                            Text(portion.label)
                                .font(CalorynTheme.numericCaption)
                                .foregroundStyle(isSelected ? CalorynTheme.warmWhite : CalorynTheme.textPrimary)
                                .padding(.horizontal, quickButtonPadding)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            isSelected
                                ? .regular.tint(CalorynTheme.sage).interactive()
                                : .regular.interactive(),
                            in: .capsule
                        )
                    }

                    if foodItem.servingInfo == nil, let serving = foodItem.defaultServingG, serving > 0 {
                        let isServingSelected = portionGrams == serving
                        let servingLabel = foodItem.servingDescription ?? "\(Int(serving))g"
                        Button {
                            withAnimation(.smooth(duration: 0.2)) {
                                portionGrams = serving
                                portionText = "\(Int(serving))"
                            }
                        } label: {
                            Text(servingLabel)
                                .font(CalorynTheme.numericCaption)
                                .foregroundStyle(isServingSelected ? CalorynTheme.warmWhite : CalorynTheme.textPrimary)
                                .padding(.horizontal, quickButtonPadding)
                                .padding(.vertical, 8)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            isServingSelected
                                ? .regular.tint(CalorynTheme.sage).interactive()
                                : .regular.interactive(),
                            in: .capsule
                        )
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
        onLogged?()
        dismiss()
    }

    private func updatePortionFromDefaultServing() {
        let defaultPortion = foodItem.defaultServingG ?? 100
        portionGrams = defaultPortion
        portionText = "\(Int(defaultPortion))"
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
    return PortionPickerView(
        foodItem: food,
        mealType: .lunch,
        logDate: .now,
        isNewFood: true
    )
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
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
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
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
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}
