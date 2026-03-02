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

                    portionInput

                    quickPortionButtons

                    macroPreview

                    mealSelector
                }
                .padding(.horizontal, BiteLogTheme.pagePadding)
                .padding(.bottom, 100)
            }
            .navigationTitle("Portion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: logFood) {
                    Text("Log Food")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .tint(BiteLogTheme.sage)
                .padding(.horizontal, BiteLogTheme.pagePadding)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.large])
    }

    private var foodHeader: some View {
        VStack(spacing: 4) {
            Text(foodItem.name)
                .font(BiteLogTheme.sectionTitle)
                .foregroundStyle(BiteLogTheme.textPrimary)
                .multilineTextAlignment(.center)

            if let brand = foodItem.brand, !brand.isEmpty {
                Text(brand)
                    .font(BiteLogTheme.caption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }
        }
        .padding(.top, 8)
    }

    private var caloriePreview: some View {
        VStack(spacing: 4) {
            Text("\(Int(previewCalories))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(BiteLogTheme.sage)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.3), value: Int(previewCalories))

            Text("calories")
                .font(BiteLogTheme.bodyText)
                .foregroundStyle(BiteLogTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }

    private var portionInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PORTION SIZE")
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)

            HStack {
                TextField("Grams", text: $portionText)
                    .font(BiteLogTheme.numericBody)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: portionText) {
                        if let value = Double(portionText), value > 0 {
                            portionGrams = value
                        }
                    }

                Text("grams")
                    .font(BiteLogTheme.bodyText)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }

            Slider(value: $portionGrams, in: 1...500, step: 1)
                .tint(BiteLogTheme.sage)
                .onChange(of: portionGrams) {
                    portionText = "\(Int(portionGrams))"
                }
        }
        .glassCard(cornerRadius: BiteLogTheme.smallCornerRadius)
    }

    private var quickPortionButtons: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(quickPortions, id: \.grams) { portion in
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            portionGrams = portion.grams
                            portionText = "\(Int(portion.grams))"
                        }
                    } label: {
                        Text(portion.label)
                            .font(BiteLogTheme.numericCaption)
                            .padding(.horizontal, quickButtonPadding)
                            .padding(.vertical, 8)
                    }
                    .glassEffect(
                        portionGrams == portion.grams
                            ? .regular.tint(BiteLogTheme.sage).interactive()
                            : .regular.interactive(),
                        in: .capsule
                    )
                }

                if let serving = foodItem.defaultServingG, serving > 0 {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            portionGrams = serving
                            portionText = "\(Int(serving))"
                        }
                    } label: {
                        Text("1 srv")
                            .font(BiteLogTheme.numericCaption)
                            .padding(.horizontal, quickButtonPadding)
                            .padding(.vertical, 8)
                    }
                    .glassEffect(
                        portionGrams == serving
                            ? .regular.tint(BiteLogTheme.sage).interactive()
                            : .regular.interactive(),
                        in: .capsule
                    )
                }
            }
        }
    }

    private var macroPreview: some View {
        HStack(spacing: BiteLogTheme.cardSpacing) {
            macroPill("Protein", value: previewProtein, color: BiteLogTheme.proteinColor)
            macroPill("Carbs", value: previewCarbs, color: BiteLogTheme.carbColor)
            macroPill("Fat", value: previewFat, color: BiteLogTheme.fatColor)
        }
    }

    private func macroPill(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)
            Text(value.macroFormatted)
                .font(BiteLogTheme.numericBody)
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.3), value: value.macroFormatted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: BiteLogTheme.smallCornerRadius)
    }

    private var mealSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEAL")
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)

            Picker("Meal", selection: $selectedMeal) {
                ForEach(MealType.allCases) { meal in
                    Label(meal.displayName, systemImage: meal.iconName)
                        .tag(meal)
                }
            }
            .pickerStyle(.segmented)
        }
        .glassCard(cornerRadius: BiteLogTheme.smallCornerRadius)
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
}
