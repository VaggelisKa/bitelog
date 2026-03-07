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

    @State private var usePortionMode: Bool = false
    @State private var portionQuantity: Double = 1
    @State private var quantityText: String = "1"
    @State private var selectedPortionIndex: Int = 0

    @ScaledMetric private var quickButtonPadding: CGFloat = 10

    private let quickGramPortions: [(label: String, grams: Double)] = [
        ("50g", 50),
        ("100g", 100),
        ("150g", 150),
        ("200g", 200),
    ]

    private var availablePortions: [PortionOption] {
        var options = foodItem.portionOptions
        if options.isEmpty, let serving = foodItem.defaultServingG, serving > 0 {
            let desc = foodItem.servingDescription ?? "serving"
            options.append(PortionOption(name: desc, gramsPerPortion: serving))
        }
        return options
    }

    private var hasPortionOptions: Bool {
        !availablePortions.isEmpty
    }

    private var selectedPortion: PortionOption? {
        let portions = availablePortions
        guard !portions.isEmpty, selectedPortionIndex < portions.count else { return nil }
        return portions[selectedPortionIndex]
    }

    init(foodItem: FoodItem, mealType: MealType, logDate: Date, isNewFood: Bool, snackIndex: Int = 0, onLogged: (() -> Void)? = nil) {
        self.foodItem = foodItem
        self.mealType = mealType
        self.logDate = logDate
        self.isNewFood = isNewFood
        self.snackIndex = snackIndex
        self.onLogged = onLogged
        self._selectedMeal = State(initialValue: mealType)

        let portions = foodItem.portionOptions
        let hasPortions = !portions.isEmpty || (foodItem.defaultServingG ?? 0) > 0

        if hasPortions {
            self._usePortionMode = State(initialValue: true)
            let servingG = portions.first?.gramsPerPortion ?? foodItem.defaultServingG ?? 100
            self._portionGrams = State(initialValue: servingG)
            self._portionText = State(initialValue: "\(Int(servingG))")
            self._portionQuantity = State(initialValue: 1)
            self._quantityText = State(initialValue: "1")
        } else {
            let defaultPortion = foodItem.defaultServingG ?? 100
            self._portionGrams = State(initialValue: defaultPortion)
            self._portionText = State(initialValue: "\(Int(defaultPortion))")
        }
    }

    private var previewCalories: Double { foodItem.calories(forGrams: portionGrams) }
    private var previewProtein: Double { foodItem.protein(forGrams: portionGrams) }
    private var previewCarbs: Double { foodItem.carbs(forGrams: portionGrams) }
    private var previewFat: Double { foodItem.fat(forGrams: portionGrams) }

    private var currentPortionLabel: String {
        if usePortionMode, let portion = selectedPortion {
            return portion.label(quantity: portionQuantity)
        }
        return "\(Int(portionGrams))g"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    foodHeader

                    caloriePreview

                    if hasPortionOptions {
                        modeToggle
                    }

                    if usePortionMode {
                        portionBasedInput
                    } else {
                        gramBasedInput
                    }

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

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("Input mode", selection: $usePortionMode) {
            Text("Portions").tag(true)
            Text("Grams").tag(false)
        }
        .pickerStyle(.segmented)
        .onChange(of: usePortionMode) {
            if usePortionMode {
                syncGramsFromPortion()
            }
        }
    }

    // MARK: - Portion-Based Input

    private var portionBasedInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PORTION")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            if availablePortions.count > 1 {
                portionTypePicker
            }

            quantityRow

            quickPortionButtons

            Text("\(Int(portionGrams))g")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private var portionTypePicker: some View {
        HStack {
            Text("Type")
                .font(CalorynTheme.bodyText)
                .foregroundStyle(CalorynTheme.textPrimary)

            Spacer()

            Picker("Portion type", selection: $selectedPortionIndex) {
                ForEach(Array(availablePortions.enumerated()), id: \.offset) { index, option in
                    Text(option.name).tag(index)
                }
            }
            .tint(CalorynTheme.sage)
            .onChange(of: selectedPortionIndex) {
                syncGramsFromPortion()
            }
        }
    }

    private var quantityRow: some View {
        HStack(spacing: 16) {
            Button {
                adjustQuantity(by: -0.5)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(portionQuantity > 0.5 ? CalorynTheme.sage : CalorynTheme.textSecondary.opacity(0.4))
            }
            .disabled(portionQuantity <= 0.25)
            .accessibilityLabel("Decrease quantity")

            VStack(spacing: 2) {
                TextField("1", text: $quantityText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(CalorynTheme.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .onChange(of: quantityText) {
                        if let value = Double(quantityText), value > 0 {
                            portionQuantity = value
                            syncGramsFromPortion()
                        }
                    }

                if let portion = selectedPortion {
                    Text(portion.name)
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.textSecondary)
                }
            }

            Button {
                adjustQuantity(by: 0.5)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CalorynTheme.sage)
            }
            .accessibilityLabel("Increase quantity")
        }
        .frame(maxWidth: .infinity)
    }

    private var quickPortionButtons: some View {
        let quickQuantities: [Double] = [0.5, 1, 1.5, 2, 3]

        return GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(quickQuantities, id: \.self) { qty in
                    let isSelected = portionQuantity == qty
                    let label = qty.truncatingRemainder(dividingBy: 1) == 0
                        ? "\(Int(qty))"
                        : String(format: "%.1f", qty)

                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            portionQuantity = qty
                            quantityText = label
                            syncGramsFromPortion()
                        }
                    } label: {
                        Text(label)
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
            }
        }
    }

    // MARK: - Gram-Based Input

    private var gramBasedInput: some View {
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
                    ForEach(quickGramPortions, id: \.grams) { portion in
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

                    if let serving = foodItem.defaultServingG, serving > 0 {
                        let isServingSelected = portionGrams == serving
                        Button {
                            withAnimation(.smooth(duration: 0.2)) {
                                portionGrams = serving
                                portionText = "\(Int(serving))"
                            }
                        } label: {
                            Text("1 srv")
                                .font(CalorynTheme.numericCaption)
                                .foregroundStyle(isServingSelected ? CalorynTheme.warmWhite : CalorynTheme.textPrimary)
                                .padding(.horizontal, quickButtonPadding)
                                .padding(.vertical, 8)
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

    // MARK: - Actions

    private func adjustQuantity(by delta: Double) {
        let newQty = max(0.25, portionQuantity + delta)
        withAnimation(.smooth(duration: 0.2)) {
            portionQuantity = newQty
            quantityText = formatQuantity(newQty)
            syncGramsFromPortion()
        }
    }

    private func syncGramsFromPortion() {
        guard let portion = selectedPortion else { return }
        let grams = portion.gramsPerPortion * portionQuantity
        portionGrams = grams
        portionText = "\(Int(grams))"
    }

    private func formatQuantity(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
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

    private func updatePortionFromDefaultServing() {
        let defaultPortion = foodItem.defaultServingG ?? 100
        portionGrams = defaultPortion
        portionText = "\(Int(defaultPortion))"
        if usePortionMode {
            portionQuantity = 1
            quantityText = "1"
            selectedPortionIndex = 0
            syncGramsFromPortion()
        }
    }
}

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
