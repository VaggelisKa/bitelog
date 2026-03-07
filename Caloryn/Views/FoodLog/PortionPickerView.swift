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

    @State private var quantity: Double = 1
    @State private var quantityText: String = "1"
    @State private var selectedUnitIndex: Int = 0
    @State private var selectedMeal: MealType
    @State private var showingCustomFoodEditor = false

    @ScaledMetric private var chipPadding: CGFloat = 10

    private var unitOptions: [UnitOption] {
        var options: [UnitOption] = []

        for portion in foodItem.portionOptions {
            options.append(.portion(portion))
        }

        if options.isEmpty, let serving = foodItem.defaultServingG, serving > 0 {
            let desc = foodItem.servingDescription ?? "serving"
            options.append(.portion(PortionOption(name: desc, gramsPerPortion: serving)))
        }

        if options.isEmpty {
            options.append(.portion(PortionOption(name: "serving", gramsPerPortion: 100)))
        }

        options.append(.grams)
        return options
    }

    private var selectedUnit: UnitOption {
        let options = unitOptions
        guard selectedUnitIndex < options.count else { return options[0] }
        return options[selectedUnitIndex]
    }

    private var isGramsMode: Bool {
        selectedUnit == .grams
    }

    private var portionGrams: Double {
        switch selectedUnit {
        case .grams:
            return quantity
        case .portion(let option):
            return option.gramsPerPortion * quantity
        }
    }

    init(foodItem: FoodItem, mealType: MealType, logDate: Date, isNewFood: Bool, snackIndex: Int = 0, onLogged: (() -> Void)? = nil) {
        self.foodItem = foodItem
        self.mealType = mealType
        self.logDate = logDate
        self.isNewFood = isNewFood
        self.snackIndex = snackIndex
        self.onLogged = onLogged
        self._selectedMeal = State(initialValue: mealType)
        self._selectedUnitIndex = State(initialValue: 0)
        self._quantity = State(initialValue: 1)
        self._quantityText = State(initialValue: "1")
    }

    private var previewCalories: Double { foodItem.calories(forGrams: portionGrams) }
    private var previewProtein: Double { foodItem.protein(forGrams: portionGrams) }
    private var previewCarbs: Double { foodItem.carbs(forGrams: portionGrams) }
    private var previewFat: Double { foodItem.fat(forGrams: portionGrams) }

    private var currentPortionLabel: String {
        switch selectedUnit {
        case .grams:
            return "\(Int(quantity))g"
        case .portion(let option):
            return option.label(quantity: quantity)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    foodHeader

                    caloriePreview

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
                    onSaved: { _ in },
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

    // MARK: - Food Header

    private var foodHeader: some View {
        VStack(spacing: 4) {
            Text(foodItem.name)
                .font(CalorynTheme.sectionTitle)
                .foregroundStyle(CalorynTheme.textPrimary)
                .multilineTextAlignment(.center)

            if let brand = foodItem.brand, !brand.isEmpty {
                Text(brand)
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Calorie Preview

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

    // MARK: - Portion Input

    private var portionInput: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HOW MUCH")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            quantityRow

            unitSelector

            quickButtons

            if !isGramsMode {
                Text("= \(Int(portionGrams))g")
                    .font(CalorynTheme.numericCaption)
                    .foregroundStyle(CalorynTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private var quantityRow: some View {
        HStack(spacing: 16) {
            Button {
                adjustQuantity(by: isGramsMode ? -25 : -0.5)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(quantity > minQuantity ? CalorynTheme.sage : CalorynTheme.textSecondary.opacity(0.4))
            }
            .disabled(quantity <= minQuantity)
            .accessibilityLabel("Decrease quantity")

            VStack(spacing: 2) {
                TextField(isGramsMode ? "100" : "1", text: $quantityText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(CalorynTheme.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
                    .onChange(of: quantityText) {
                        if let value = Double(quantityText), value > 0 {
                            quantity = value
                        }
                    }

                Text(unitLabel)
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }

            Button {
                adjustQuantity(by: isGramsMode ? 25 : 0.5)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CalorynTheme.sage)
            }
            .accessibilityLabel("Increase quantity")
        }
        .frame(maxWidth: .infinity)
    }

    private var unitSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Array(unitOptions.enumerated()), id: \.offset) { index, option in
                        let isSelected = selectedUnitIndex == index
                        Button {
                            switchUnit(to: index)
                        } label: {
                            Text(option.chipLabel)
                                .font(CalorynTheme.numericCaption)
                                .foregroundStyle(isSelected ? CalorynTheme.warmWhite : CalorynTheme.textPrimary)
                                .padding(.horizontal, chipPadding)
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
                }
            }
        }
    }

    private var quickButtons: some View {
        let values = isGramsMode
            ? [50.0, 100, 150, 200, 300]
            : [0.5, 1, 1.5, 2, 3]

        return GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { val in
                    let isSelected = quantity == val
                    let label = formatQuantityLabel(val)

                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            quantity = val
                            quantityText = formatQuantity(val)
                        }
                    } label: {
                        Text(label)
                            .font(CalorynTheme.numericCaption)
                            .foregroundStyle(isSelected ? CalorynTheme.warmWhite : CalorynTheme.textPrimary)
                            .padding(.horizontal, chipPadding)
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
            }
        }
    }

    // MARK: - Macro Preview

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

    // MARK: - Meal Selector

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

    // MARK: - Helpers

    private var minQuantity: Double {
        isGramsMode ? 1 : 0.25
    }

    private var unitLabel: String {
        switch selectedUnit {
        case .grams: return "grams"
        case .portion(let option): return option.name
        }
    }

    private func formatQuantityLabel(_ value: Double) -> String {
        if isGramsMode {
            return "\(Int(value))g"
        }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }

    private func formatQuantity(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }

    private func switchUnit(to index: Int) {
        let wasGrams = isGramsMode
        let oldGrams = portionGrams

        withAnimation(.smooth(duration: 0.2)) {
            selectedUnitIndex = index
        }

        let newOption = unitOptions[index]
        switch newOption {
        case .grams:
            quantity = oldGrams
            quantityText = "\(Int(oldGrams))"
        case .portion(let option) where wasGrams:
            let converted = max(0.5, (oldGrams / option.gramsPerPortion * 2).rounded() / 2)
            quantity = converted
            quantityText = formatQuantity(converted)
        case .portion:
            break
        }
    }

    private func adjustQuantity(by delta: Double) {
        let newQty = max(minQuantity, quantity + delta)
        withAnimation(.smooth(duration: 0.2)) {
            quantity = newQty
            quantityText = isGramsMode ? "\(Int(newQty))" : formatQuantity(newQty)
        }
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
            portionLabel: currentPortionLabel,
            snackIndex: selectedMeal == .snack ? snackIndex : 0
        )
        modelContext.insert(entry)
        onLogged?()
        dismiss()
    }
}

// MARK: - Unit Option

private enum UnitOption: Equatable {
    case grams
    case portion(PortionOption)

    var chipLabel: String {
        switch self {
        case .grams: return "grams"
        case .portion(let option): return option.name
        }
    }
}

// MARK: - Preview

#Preview {
    let food = FoodItem(
        name: "Eggs",
        brand: nil,
        caloriesPer100g: 155,
        proteinPer100g: 13,
        carbsPer100g: 1.1,
        fatPer100g: 11,
        defaultServingG: 50,
        servingDescription: "egg",
        portionOptions: [
            PortionOption(name: "egg", gramsPerPortion: 50),
            PortionOption(name: "egg white", gramsPerPortion: 33),
        ]
    )
    return PortionPickerView(
        foodItem: food,
        mealType: .breakfast,
        logDate: .now,
        isNewFood: true
    )
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}

#Preview("No serving data") {
    let food = FoodItem(
        name: "Orange",
        brand: nil,
        caloriesPer100g: 47,
        proteinPer100g: 0.9,
        carbsPer100g: 12,
        fatPer100g: 0.1
    )
    return PortionPickerView(
        foodItem: food,
        mealType: .lunch,
        logDate: .now,
        isNewFood: true
    )
    .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}
