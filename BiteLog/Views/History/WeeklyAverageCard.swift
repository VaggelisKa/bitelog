import SwiftUI
import Charts

struct WeeklyAverageCard: View {
    let average: Double
    let target: Int
    let dailyData: [(date: Date, calories: Double)]

    private var difference: Int {
        Int(average) - target
    }

    private var differenceLabel: String {
        if average == 0 { return "No data yet" }
        if difference > 0 {
            return "+\(difference) over target"
        } else if difference < 0 {
            return "\(abs(difference)) under target"
        }
        return "On target"
    }

    private var weeklyTotal: Double {
        dailyData.reduce(0) { $0 + $1.calories }
    }

    private var daysWithData: Int {
        dailyData.filter { $0.calories > 0 }.count
    }

    private var totalDifference: Int {
        Int(weeklyTotal) - (target * daysWithData)
    }

    private var totalDifferenceLabel: String {
        if weeklyTotal == 0 { return "No data yet" }
        if totalDifference > 0 {
            return "+\(totalDifference) over"
        } else if totalDifference < 0 {
            return "\(abs(totalDifference)) under"
        }
        return "On target"
    }

    private var differenceColor: Color {
        if average == 0 { return BiteLogTheme.textSecondary }
        return difference > 0 ? BiteLogTheme.terracotta : BiteLogTheme.sage
    }

    private var totalDifferenceColor: Color {
        if weeklyTotal == 0 { return BiteLogTheme.textSecondary }
        return totalDifference > 0 ? BiteLogTheme.terracotta : BiteLogTheme.sage
    }

    private var hasAnyData: Bool {
        average > 0 || weeklyTotal > 0
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("This Week")
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)
                .textCase(.uppercase)

            if hasAnyData {
                averageSummary
            }

            chartContent
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }

    // MARK: - Compact average summary

    private var averageSummary: some View {
        HStack(alignment: .top, spacing: 0) {
            statColumn(
                value: average > 0 ? "\(Int(average))" : "—",
                unit: "kcal/day",
                detail: differenceLabel,
                detailColor: differenceColor
            )

            Spacer()

            statColumn(
                value: weeklyTotal > 0
                    ? "\(Int(weeklyTotal).formatted())"
                    : "—",
                unit: "kcal total",
                detail: totalDifferenceLabel,
                detailColor: totalDifferenceColor
            )
        }
    }

    private func statColumn(
        value: String,
        unit: String,
        detail: String?,
        detailColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        value == "—"
                            ? BiteLogTheme.textSecondary
                            : BiteLogTheme.textPrimary
                    )

                Text(unit)
                    .font(BiteLogTheme.caption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }

            if let detail {
                Text(detail)
                    .font(BiteLogTheme.numericCaption)
                    .foregroundStyle(detailColor)
            }
        }
    }

    // MARK: - Bar chart

    private var chartContent: some View {
        let today = Calendar.current.startOfDay(for: .now)
        let pastOrTodayData = dailyData.filter { $0.date <= today }
        let maxCalories = max(
            pastOrTodayData.map(\.calories).max() ?? 0,
            max(Double(target), average)
        )

        return Chart {
            ForEach(pastOrTodayData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Calories", item.calories)
                )
                .foregroundStyle(
                    item.calories > Double(target)
                        ? BiteLogTheme.terracotta
                        : BiteLogTheme.sage
                )
                .cornerRadius(4)
            }

            RuleMark(y: .value("Target", target))
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [6, 4]))
                .foregroundStyle(BiteLogTheme.textSecondary.opacity(0.6))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Target")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(BiteLogTheme.textSecondary)
                }

            if average > 0 {
                RuleMark(y: .value("Avg", average))
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                    .foregroundStyle(BiteLogTheme.terracotta.opacity(0.8))
                    .annotation(position: .bottom, alignment: .trailing) {
                        Text("Avg")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(BiteLogTheme.terracotta)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 10))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.system(size: 10))
            }
        }
        .chartYScale(domain: 0 ... (maxCalories * 1.15))
        .chartXScale(domain: dailyData.first!.date ... dailyData.last!.date)
        .frame(height: 160)
    }
}

#Preview {
    let weekDates = Date.datesForCurrentWeek()
    let sampleCalories: [Double] = [1850, 2100, 1950, 2250, 1700, 0, 0]
    let dailyData = zip(weekDates, sampleCalories).map { (date: $0, calories: $1) }

    VStack(spacing: 16) {
        WeeklyAverageCard(
            average: 1970,
            target: 2000,
            dailyData: dailyData
        )
        WeeklyAverageCard(
            average: 0,
            target: 2000,
            dailyData: weekDates.map { (date: $0, calories: 0.0) }
        )
    }
    .padding()
}
