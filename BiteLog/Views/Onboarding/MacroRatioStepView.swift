import SwiftUI

struct MacroRatioStepView: View {
    let calorieTarget: Int
    @Binding var proteinRatio: Double
    @Binding var carbRatio: Double
    @Binding var fatRatio: Double
    var onComplete: () -> Void

    private var total: Double { proteinRatio + carbRatio + fatRatio }
    private var isValid: Bool { abs(total - 1.0) <= 0.01 }

    private var proteinGrams: Double {
        NutritionCalculator.macroGrams(calories: Double(calorieTarget), ratio: proteinRatio, caloriesPerGram: 4)
    }

    private var carbGrams: Double {
        NutritionCalculator.macroGrams(calories: Double(calorieTarget), ratio: carbRatio, caloriesPerGram: 4)
    }

    private var fatGrams: Double {
        NutritionCalculator.macroGrams(calories: Double(calorieTarget), ratio: fatRatio, caloriesPerGram: 9)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Macro Ratios")
                        .font(BiteLogTheme.sectionTitle)
                        .foregroundStyle(BiteLogTheme.textPrimary)
                    Text("Fine-tune how your \(calorieTarget) kcal are split.")
                        .font(BiteLogTheme.bodyText)
                        .foregroundStyle(BiteLogTheme.textSecondary)
                }
                .padding(.top, 8)

                macroSlider(
                    name: "Protein",
                    ratio: $proteinRatio,
                    grams: proteinGrams,
                    color: BiteLogTheme.proteinColor,
                    range: 0.10...0.50
                )

                macroSlider(
                    name: "Carbs",
                    ratio: $carbRatio,
                    grams: carbGrams,
                    color: BiteLogTheme.carbColor,
                    range: 0.10...0.60
                )

                macroSlider(
                    name: "Fat",
                    ratio: $fatRatio,
                    grams: fatGrams,
                    color: BiteLogTheme.fatColor,
                    range: 0.10...0.50
                )

                if !isValid {
                    Text("Ratios should total 100% (currently \(Int(total * 100))%)")
                        .font(BiteLogTheme.caption)
                        .foregroundStyle(BiteLogTheme.terracotta)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, BiteLogTheme.pagePadding)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onComplete) {
                Text("Start Tracking")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .tint(BiteLogTheme.sage)
            .padding(.horizontal, BiteLogTheme.pagePadding)
            .padding(.bottom, 16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip", action: onComplete)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }
        }
    }

    // MARK: - Macro Slider

    private func macroSlider(
        name: String,
        ratio: Binding<Double>,
        grams: Double,
        color: Color,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(BiteLogTheme.itemTitle)
                    .foregroundStyle(BiteLogTheme.textPrimary)
                Spacer()
                Text("\(Int(ratio.wrappedValue * 100))%")
                    .font(BiteLogTheme.numericBody)
                    .foregroundStyle(color)
                Text("·")
                    .foregroundStyle(BiteLogTheme.textSecondary)
                Text("\(Int(grams))g")
                    .font(BiteLogTheme.numericCaption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }
            Slider(value: ratio, in: range, step: 0.05)
                .tint(color)
        }
        .glassCard(cornerRadius: BiteLogTheme.smallCornerRadius)
    }
}

#Preview {
    NavigationStack {
        MacroRatioStepView(
            calorieTarget: 2000,
            proteinRatio: .constant(0.30),
            carbRatio: .constant(0.40),
            fatRatio: .constant(0.30)
        ) { }
    }
}
