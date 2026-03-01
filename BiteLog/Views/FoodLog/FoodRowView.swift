import SwiftUI

struct FoodRowView: View {
    let name: String
    let brand: String?
    let caloriesPer100g: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(BiteLogTheme.itemTitle)
                    .foregroundStyle(BiteLogTheme.textPrimary)
                    .lineLimit(1)

                if let brand, !brand.isEmpty {
                    Text(brand)
                        .font(BiteLogTheme.caption)
                        .foregroundStyle(BiteLogTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(caloriesPer100g))")
                    .font(BiteLogTheme.numericBody)
                    .foregroundStyle(BiteLogTheme.textPrimary)
                Text("kcal/100g")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(BiteLogTheme.textSecondary)
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
    }
}
