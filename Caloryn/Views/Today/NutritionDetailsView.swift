import SwiftUI

struct NutritionDetailsView: View {
    let date: Date
    let entries: [FoodLogEntry]
    let calorieTarget: Int
    let proteinTarget: Double
    let carbTarget: Double
    let fatTarget: Double

    @Environment(\.dismiss) private var dismiss

    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.proteinG }
    }

    private var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.carbsG }
    }

    private var totalFat: Double {
        entries.reduce(0) { $0 + $1.fatG }
    }

    private var totalFiber: Double {
        entries.reduce(0) { $0 + $1.fiberG }
    }

    private var calorieAccentColor: Color {
        totalCalories > Double(calorieTarget) ? CalorynTheme.terracotta : CalorynTheme.sage
    }

    private var fiberSources: [FoodLogEntry] {
        Array(
            entries
                .filter { $0.fiberG > 0 }
                .sorted { $0.fiberG > $1.fiberG }
                .prefix(5)
        )
    }

    private var totalSolubleFiber: Double? {
        total(\.solubleFiberG)
    }

    private var totalInsolubleFiber: Double? {
        total(\.insolubleFiberG)
    }

    private var proteinDetails: [DetailNutrient] {
        [
            detail("casein", "Casein", \.caseinG),
            detail("serum-proteins", "Serum proteins", \.serumProteinsG)
        ].compactMap { $0 }
    }

    private var carbDetails: [DetailNutrient] {
        [
            detail("sugars", "Sugars", \.sugarsG),
            detail("added-sugars", "Added sugars", \.addedSugarsG),
            detail("sucrose", "Sucrose", \.sucroseG),
            detail("glucose", "Glucose", \.glucoseG),
            detail("fructose", "Fructose", \.fructoseG),
            detail("lactose", "Lactose", \.lactoseG),
            detail("maltose", "Maltose", \.maltoseG),
            detail("maltodextrins", "Maltodextrins", \.maltodextrinsG),
            detail("starch", "Starch", \.starchG),
            detail("polyols", "Polyols", \.polyolsG)
        ].compactMap { $0 }
    }

    private var fatDetails: [DetailNutrient] {
        [
            detail("saturated-fat", "Saturated fat", \.saturatedFatG),
            detail("trans-fat", "Trans fat", \.transFatG),
            detail("monounsaturated-fat", "Monounsaturated", \.monounsaturatedFatG),
            detail("polyunsaturated-fat", "Polyunsaturated", \.polyunsaturatedFatG),
            detail("omega-3-fat", "Omega-3 fat", \.omega3FatG),
            detail("omega-6-fat", "Omega-6 fat", \.omega6FatG),
            detail("omega-9-fat", "Omega-9 fat", \.omega9FatG),
            detail("cholesterol", "Cholesterol", \.cholesterolG, unit: .milligramsFromGrams)
        ].compactMap { $0 }
    }

    private var saltDetails: [DetailNutrient] {
        [
            detail("salt", "Salt", \.saltG),
            detail("sodium", "Sodium", \.sodiumG, unit: .milligramsFromGrams)
        ].compactMap { $0 }
    }

    private var otherDetails: [DetailNutrient] {
        [
            detail("alcohol", "Alcohol", \.alcoholG)
        ].compactMap { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CalorynTheme.cardSpacing) {
                    calorieSummary
                    fiberFocus
                    macroGrid
                    detailSections
                    dataQualityNote
                }
                .padding(.horizontal, CalorynTheme.pagePadding)
                .padding(.vertical, CalorynTheme.cardSpacing)
            }
            .navigationTitle(date.shortFormatted)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private var calorieSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Nutrition")
                .font(CalorynTheme.sectionTitle)
                .foregroundStyle(CalorynTheme.textPrimary)

            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(totalCalories.rounded()))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(calorieAccentColor)
                    .contentTransition(.numericText())

                Text("/ \(calorieTarget) kcal")
                    .font(CalorynTheme.numericBody)
                    .foregroundStyle(CalorynTheme.textSecondary)
            }

            progressBar(
                current: totalCalories,
                target: Double(calorieTarget),
                color: calorieAccentColor
            )
        }
        .glassCard()
    }

    private var macroGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            nutrientTile("Protein", value: totalProtein, target: proteinTarget, color: CalorynTheme.proteinColor)
            nutrientTile("Carbs", value: totalCarbs, target: carbTarget, color: CalorynTheme.carbColor)
            nutrientTile("Fat", value: totalFat, target: fatTarget, color: CalorynTheme.fatColor)
        }
    }

    private var fiberFocus: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "leaf")
                    .foregroundStyle(CalorynTheme.fiberColor)

                Text("Fiber")
                    .font(CalorynTheme.itemTitle)
                    .foregroundStyle(CalorynTheme.textPrimary)

                Spacer()

                Text(totalFiber.macroFormatted)
                    .font(CalorynTheme.numericBody)
                    .foregroundStyle(CalorynTheme.fiberColor)
            }

            if fiberSources.isEmpty {
                Text(entries.isEmpty ? "No foods logged for this day." : "No fiber logged for these foods.")
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(fiberSources) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.foodName)
                                    .font(CalorynTheme.bodyText)
                                    .foregroundStyle(CalorynTheme.textPrimary)
                                    .lineLimit(1)

                                Text("\(Int(entry.portionGrams.rounded()))g")
                                    .font(CalorynTheme.caption)
                                    .foregroundStyle(CalorynTheme.textSecondary)
                            }

                            Spacer()

                            Text(entry.fiberG.macroFormatted)
                                .font(CalorynTheme.numericCaption)
                                .foregroundStyle(CalorynTheme.fiberColor)
                        }
                        .padding(.vertical, 8)

                        if entry.id != fiberSources.last?.id {
                            Divider()
                                .foregroundStyle(CalorynTheme.stone.opacity(0.3))
                        }
                    }
                }
            }

            if let totalSolubleFiber {
                Divider()
                    .foregroundStyle(CalorynTheme.stone.opacity(0.3))

                detailRow(label: "Soluble fiber", value: totalSolubleFiber.macroFormatted)
            }

            if let totalInsolubleFiber {
                Divider()
                    .foregroundStyle(CalorynTheme.stone.opacity(0.3))

                detailRow(label: "Insoluble fiber", value: totalInsolubleFiber.macroFormatted)
            }
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    @ViewBuilder
    private var detailSections: some View {
        if !proteinDetails.isEmpty {
            detailSection("Protein Details", systemImage: "bolt", color: CalorynTheme.proteinColor, items: proteinDetails)
        }

        if !carbDetails.isEmpty {
            detailSection("Carb Details", systemImage: "chart.bar.xaxis", color: CalorynTheme.carbColor, items: carbDetails)
        }

        if !fatDetails.isEmpty {
            detailSection("Fat Details", systemImage: "drop", color: CalorynTheme.fatColor, items: fatDetails)
        }

        if !saltDetails.isEmpty {
            detailSection("Salt", systemImage: "circle.grid.cross", color: CalorynTheme.stone, items: saltDetails)
        }

        if !otherDetails.isEmpty {
            detailSection("Other", systemImage: "ellipsis", color: CalorynTheme.textSecondary, items: otherDetails)
        }
    }

    private var dataQualityNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            Text("Detailed nutrients come from product data and may be missing or inaccurate for some foods.")
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private func detailSection(_ title: String, systemImage: String, color: Color, items: [DetailNutrient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)

                Text(title)
                    .font(CalorynTheme.itemTitle)
                    .foregroundStyle(CalorynTheme.textPrimary)
            }

            VStack(spacing: 0) {
                ForEach(items) { item in
                    detailRow(label: item.label, value: formattedDetailValue(item))
                        .padding(.vertical, 7)

                    if item.id != items.last?.id {
                        Divider()
                            .foregroundStyle(CalorynTheme.stone.opacity(0.3))
                    }
                }
            }
        }
        .glassCard(cornerRadius: CalorynTheme.smallCornerRadius)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(CalorynTheme.bodyText)
                .foregroundStyle(CalorynTheme.textPrimary)

            Spacer()

            Text(value)
                .font(CalorynTheme.numericBody)
                .foregroundStyle(CalorynTheme.textSecondary)
        }
    }

    private func nutrientTile(_ label: String, value: Double, target: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)

            Text(value.macroFormatted)
                .font(CalorynTheme.numericBody)
                .foregroundStyle(color)
                .contentTransition(.numericText())

            if let target, target > 0 {
                progressBar(current: value, target: target, color: color)

                Text("of \(target.macroFormatted)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(CalorynTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("today")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(CalorynTheme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: CalorynTheme.smallCornerRadius))
        .accessibilityElement(children: .combine)
    }

    private func progressBar(current: Double, target: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.15))

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(current / target, 1))
            }
        }
        .frame(height: 7)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    private func detail(
        _ id: String,
        _ label: String,
        _ keyPath: KeyPath<FoodLogEntry, Double?>,
        unit: DetailNutrient.Unit = .grams
    ) -> DetailNutrient? {
        guard let value = total(keyPath) else { return nil }
        return DetailNutrient(id: id, label: label, value: value, unit: unit)
    }

    private func total(_ keyPath: KeyPath<FoodLogEntry, Double?>) -> Double? {
        let values = entries.map { $0[keyPath: keyPath] }
        guard values.contains(where: { $0 != nil }) else { return nil }
        return values.reduce(0) { $0 + ($1 ?? 0) }
    }

    private func formattedDetailValue(_ item: DetailNutrient) -> String {
        switch item.unit {
        case .grams:
            item.value.macroFormatted
        case .milligramsFromGrams:
            "\(Int((item.value * 1000).rounded()))mg"
        }
    }
}

private struct DetailNutrient: Identifiable {
    enum Unit {
        case grams
        case milligramsFromGrams
    }

    let id: String
    let label: String
    let value: Double
    let unit: Unit
}

#Preview {
    let oatmeal = FoodItem(
        name: "Oatmeal",
        caloriesPer100g: 389,
        proteinPer100g: 16.9,
        carbsPer100g: 66.3,
        fatPer100g: 6.9,
        fiberPer100g: 10.6,
        sugarsPer100g: 0.9,
        sucrosePer100g: 0.2,
        starchPer100g: 55,
        saturatedFatPer100g: 1.2,
        omega3FatPer100g: 0.1,
        saltPer100g: 0.02
    )
    let apple = FoodItem(
        name: "Apple",
        caloriesPer100g: 52,
        proteinPer100g: 0.3,
        carbsPer100g: 14,
        fatPer100g: 0.2,
        fiberPer100g: 2.4,
        sugarsPer100g: 10.4,
        glucosePer100g: 2.4,
        fructosePer100g: 5.9,
        insolubleFiberPer100g: 1.8
    )
    NutritionDetailsView(
        date: .now,
        entries: [
            FoodLogEntry(date: .now, mealType: .breakfast, foodItem: oatmeal, portionGrams: 80),
            FoodLogEntry(date: .now, mealType: .snack, foodItem: apple, portionGrams: 120)
        ],
        calorieTarget: 2000,
        proteinTarget: 120,
        carbTarget: 200,
        fatTarget: 65
    )
}
