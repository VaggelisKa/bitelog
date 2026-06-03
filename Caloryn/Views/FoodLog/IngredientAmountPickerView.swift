import SwiftUI

struct RecipeIngredientDraft: Identifiable, Hashable {
    var id: UUID
    var name: String
    var brand: String?
    var portionGrams: Double
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        brand: String?,
        portionGrams: Double,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.portionGrams = portionGrams
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.sortOrder = sortOrder
    }

    init(from foodItem: FoodItem, sortOrder: Int) {
        self.init(
            name: foodItem.name,
            brand: foodItem.brand,
            portionGrams: foodItem.defaultServingG ?? 100,
            caloriesPer100g: foodItem.caloriesPer100g,
            proteinPer100g: foodItem.proteinPer100g,
            carbsPer100g: foodItem.carbsPer100g,
            fatPer100g: foodItem.fatPer100g,
            sortOrder: sortOrder
        )
    }

    init(from ingredient: RecipeIngredient) {
        self.init(
            id: ingredient.id,
            name: ingredient.name,
            brand: ingredient.brand,
            portionGrams: ingredient.portionGrams,
            caloriesPer100g: ingredient.caloriesPer100g,
            proteinPer100g: ingredient.proteinPer100g,
            carbsPer100g: ingredient.carbsPer100g,
            fatPer100g: ingredient.fatPer100g,
            sortOrder: ingredient.sortOrder
        )
    }

    var calories: Double { caloriesPer100g * portionGrams / 100 }
    var proteinG: Double { proteinPer100g * portionGrams / 100 }
    var carbsG: Double { carbsPer100g * portionGrams / 100 }
    var fatG: Double { fatPer100g * portionGrams / 100 }
}

struct IngredientAmountPickerView: View {
    let ingredient: RecipeIngredientDraft
    var onSave: (RecipeIngredientDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var gramsText: String
    @FocusState private var isAmountFocused: Bool

    private var grams: Double {
        parseDecimal(gramsText) ?? 0
    }

    private var canSave: Bool {
        grams > 0
    }

    private var previewCalories: Double {
        ingredient.caloriesPer100g * grams / 100
    }

    private var previewProtein: Double {
        ingredient.proteinPer100g * grams / 100
    }

    private var previewCarbs: Double {
        ingredient.carbsPer100g * grams / 100
    }

    private var previewFat: Double {
        ingredient.fatPer100g * grams / 100
    }

    init(ingredient: RecipeIngredientDraft, onSave: @escaping (RecipeIngredientDraft) -> Void) {
        self.ingredient = ingredient
        self.onSave = onSave
        self._gramsText = State(initialValue: Self.formattedInitialGrams(ingredient.portionGrams))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ingredientHeader
                    caloriePreview
                    amountSection
                    macroPreview
                }
                .padding(.horizontal, CalorynTheme.pagePadding)
                .padding(.bottom, 24)
            }
            .navigationTitle("Ingredient Amount")
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

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                isAmountFocused = true
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var ingredientHeader: some View {
        VStack(spacing: 4) {
            Text(ingredient.name)
                .font(CalorynTheme.sectionTitle)
                .foregroundStyle(CalorynTheme.textPrimary)
                .multilineTextAlignment(.center)

            if let brand = ingredient.brand, !brand.isEmpty {
                Text(brand)
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

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AMOUNT")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            HStack {
                Text("Measured amount")
                    .font(CalorynTheme.bodyText)
                    .foregroundStyle(CalorynTheme.textPrimary)

                Spacer()

                TextField("100", text: $gramsText)
                    .font(CalorynTheme.numericBody)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($isAmountFocused)
                    .frame(width: 92)

                Text("g")
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
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

    private func save() {
        var updated = ingredient
        updated.portionGrams = grams
        onSave(updated)
        dismiss()
    }

    private func parseDecimal(_ string: String) -> Double? {
        let normalized = string.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private static func formattedInitialGrams(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

#Preview {
    IngredientAmountPickerView(
        ingredient: RecipeIngredientDraft(
            name: "Tomato",
            brand: nil,
            portionGrams: 100,
            caloriesPer100g: 18,
            proteinPer100g: 0.9,
            carbsPer100g: 3.9,
            fatPer100g: 0.2,
            sortOrder: 0
        ),
        onSave: { _ in }
    )
}
