import SwiftUI

struct WeeklyAverageCard: View {
    let average: Double
    let target: Int

    private var difference: Int {
        Int(average) - target
    }

    private var differenceLabel: String {
        if average == 0 { return "No data yet" }
        if difference > 0 {
            return "+\(difference) kcal over target"
        } else if difference < 0 {
            return "\(abs(difference)) kcal under target"
        }
        return "Right on target"
    }

    private var differenceColor: Color {
        if average == 0 { return BiteLogTheme.textSecondary }
        return difference > 0 ? BiteLogTheme.terracotta : BiteLogTheme.sage
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Weekly Average")
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)
                .textCase(.uppercase)

            if average > 0 {
                Text("\(Int(average))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(BiteLogTheme.textPrimary)

                Text("kcal/day")
                    .font(BiteLogTheme.caption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            } else {
                Text("—")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }

            Text(differenceLabel)
                .font(BiteLogTheme.numericCaption)
                .foregroundStyle(differenceColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }
}

#Preview {
    VStack(spacing: 16) {
        WeeklyAverageCard(average: 1950, target: 2000)
        WeeklyAverageCard(average: 2200, target: 2000)
        WeeklyAverageCard(average: 0, target: 2000)
    }
    .padding()
}
