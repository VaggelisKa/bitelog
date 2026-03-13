import SwiftUI
import SwiftData

struct CustomFoodFormView: View {
    var existingFood: FoodItem?
    var onSaved: ((FoodItem) -> Void)?
    var allowsDeletion: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var caloriesPerServing = ""
    @State private var proteinPerServing = ""
    @State private var carbsPerServing = ""
    @State private var fatPerServing = ""
    @State private var servingSizeGrams = "100"
    @State private var showingDeleteConfirmation = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, brand, calories, protein, carbs, fat, servingSize
    }

    private var isEditing: Bool { existingFood != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && (parseDecimal(caloriesPerServing) ?? -1) >= 0
        && !caloriesPerServing.isEmpty
    }

    private var servingGrams: Double {
        parseDecimal(servingSizeGrams) ?? 100
    }

    private var previewCalories: Double {
        parseDecimal(caloriesPerServing) ?? 0
    }

    private var previewProtein: Double {
        parseDecimal(proteinPerServing) ?? 0
    }

    private var previewCarbs: Double {
        parseDecimal(carbsPerServing) ?? 0
    }

    private var previewFat: Double {
        parseDecimal(fatPerServing) ?? 0
    }

    /// Parses decimal strings, supporting both "." and "," as decimal separators (locale-agnostic).
    private func parseDecimal(_ string: String) -> Double? {
        let normalized = string.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    init(existingFood: FoodItem? = nil, onSaved: ((FoodItem) -> Void)? = nil, allowsDeletion: Bool = true) {
        self.existingFood = existingFood
        self.onSaved = onSaved
        self.allowsDeletion = allowsDeletion
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    nameSection

                    caloriePreviewCard

                    nutritionSection

                    servingSizeSection

                    if isEditing && allowsDeletion {
                        deleteSection
                    }
                }
                .padding(.horizontal, CalorynTheme.pagePadding)
                .padding(.bottom, 24)
            }
            .navigationTitle(isEditing ? "Edit Custom Food" : "Create Custom Food")
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
                        saveFood()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: populateFromExisting)
            .confirmationDialog("Delete Custom Food", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive, action: deleteFood)
            } message: {
                Text("This will permanently remove \"\(name)\" from your custom foods.")
            }
        }
        .presentationDetents([.large])
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FOOD DETAILS")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            TextField("Food name (e.g. Nick's Pizza)", text: $name)
                .font(CalorynTheme.bodyText)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .name)

            TextField("Brand (optional)", text: $brand)
                .font(CalorynTheme.bodyText)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .brand)
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private var caloriePreviewCard: some View {
        VStack(spacing: 4) {
            Text("\(Int(previewCalories))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(CalorynTheme.sage)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.3), value: Int(previewCalories))

            Text("calories per serving")
                .font(CalorynTheme.bodyText)
                .foregroundStyle(CalorynTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NUTRITION PER SERVING")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            nutritionField(
                label: "Calories",
                text: $caloriesPerServing,
                unit: "kcal",
                focus: .calories,
                required: true
            )

            nutritionField(
                label: "Protein",
                text: $proteinPerServing,
                unit: "g",
                focus: .protein
            )

            nutritionField(
                label: "Carbs",
                text: $carbsPerServing,
                unit: "g",
                focus: .carbs
            )

            nutritionField(
                label: "Fat",
                text: $fatPerServing,
                unit: "g",
                focus: .fat
            )
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private func nutritionField(
        label: String,
        text: Binding<String>,
        unit: String,
        focus: Field,
        required: Bool = false
    ) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text(label)
                    .font(CalorynTheme.bodyText)
                    .foregroundStyle(CalorynTheme.textPrimary)
                if required {
                    Text("*")
                        .font(CalorynTheme.bodyText)
                        .foregroundStyle(CalorynTheme.terracotta)
                }
            }
            .frame(width: 80, alignment: .leading)

            TextField("0", text: text)
                .font(CalorynTheme.numericBody)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: focus)

            Text(unit)
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)
                .frame(width: 36, alignment: .leading)
        }
    }

    private var servingSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SERVING SIZE")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            HStack {
                Text("One serving")
                    .font(CalorynTheme.bodyText)
                    .foregroundStyle(CalorynTheme.textPrimary)

                Spacer()

                TextField("100", text: $servingSizeGrams)
                    .font(CalorynTheme.numericBody)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .focused($focusedField, equals: .servingSize)

                Text("g")
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }

            Text("The nutrition values above are for one serving of this size.")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Custom Food")
            }
            .font(.system(.body, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private func populateFromExisting() {
        guard let food = existingFood else {
            focusedField = .name
            return
        }
        name = food.name
        brand = food.brand ?? ""
        let serving = food.defaultServingG ?? 100
        servingSizeGrams = "\(Int(serving))"
        caloriesPerServing = "\(Int(food.calories(forGrams: serving)))"
        proteinPerServing = String(format: "%.1f", food.protein(forGrams: serving))
        carbsPerServing = String(format: "%.1f", food.carbs(forGrams: serving))
        fatPerServing = String(format: "%.1f", food.fat(forGrams: serving))
    }

    private func saveFood() {
        let serving = servingGrams > 0 ? servingGrams : 100
        let cal = parseDecimal(caloriesPerServing) ?? 0
        let pro = parseDecimal(proteinPerServing) ?? 0
        let carb = parseDecimal(carbsPerServing) ?? 0
        let f = parseDecimal(fatPerServing) ?? 0

        let calPer100 = cal / serving * 100
        let proPer100 = pro / serving * 100
        let carbPer100 = carb / serving * 100
        let fPer100 = f / serving * 100

        if let food = existingFood {
            food.name = name.trimmingCharacters(in: .whitespaces)
            food.brand = brand.isEmpty ? nil : brand.trimmingCharacters(in: .whitespaces)
            food.caloriesPer100g = calPer100
            food.proteinPer100g = proPer100
            food.carbsPer100g = carbPer100
            food.fatPer100g = fPer100
            food.defaultServingG = serving
            food.servingDescription = "1 serving"
            try? modelContext.save()
            onSaved?(food)
        } else {
            let food = FoodItem(
                name: name.trimmingCharacters(in: .whitespaces),
                brand: brand.isEmpty ? nil : brand.trimmingCharacters(in: .whitespaces),
                caloriesPer100g: calPer100,
                proteinPer100g: proPer100,
                carbsPer100g: carbPer100,
                fatPer100g: fPer100,
                defaultServingG: serving,
                servingDescription: "1 serving",
                isCustom: true
            )
            modelContext.insert(food)
            try? modelContext.save()
            onSaved?(food)
        }
        dismiss()
    }

    private func deleteFood() {
        if let food = existingFood {
            modelContext.delete(food)
        }
        dismiss()
    }
}

#Preview {
    CustomFoodFormView()
        .modelContainer(
            for: [UserProfile.self, FoodItem.self, FoodLogEntry.self],
            inMemory: true
        )
}
