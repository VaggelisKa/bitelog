import SwiftUI

struct FoodRowView: View {
    let name: String
    let brand: String?
    let caloriesPer100g: Double
    var isCustom: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(CalorynTheme.itemTitle)
                        .foregroundStyle(CalorynTheme.textPrimary)
                        .lineLimit(1)

                    if isCustom {
                        Text("CUSTOM")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(CalorynTheme.sage)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(CalorynTheme.sage.opacity(0.15), in: .capsule)
                    }
                }

                if let brand, !brand.isEmpty {
                    Text(brand)
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(caloriesPer100g))")
                    .font(CalorynTheme.numericBody)
                    .foregroundStyle(CalorynTheme.textPrimary)
                Text("kcal/100g")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(CalorynTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        FoodRowView(name: "Rugbroed", brand: "Schulstad", caloriesPer100g: 210)
        FoodRowView(name: "Skyr", brand: "Arla", caloriesPer100g: 63)
        FoodRowView(name: "Chicken Breast", brand: nil, caloriesPer100g: 165)
        FoodRowView(name: "Nick's Pizza", brand: "Homemade", caloriesPer100g: 267, isCustom: true)
    }
}
