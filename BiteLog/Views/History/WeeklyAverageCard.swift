import SwiftUI
import Charts

struct WeeklyAverageCard: View {
    let average: Double
    let target: Int
    let dailyData: [(date: Date, calories: Double)]

    @State private var showChart = false

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
            header

            if showChart {
                chartContent
            } else {
                averageContent
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
        .animation(.easeInOut(duration: 0.25), value: showChart)
    }

    // MARK: - Header with toggle

    private var header: some View {
        HStack {
            Spacer()
            Text(showChart ? "This Week" : "Weekly Average")
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)
                .textCase(.uppercase)
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                showChart.toggle()
            } label: {
                Image(systemName: showChart ? "number" : "chart.bar.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BiteLogTheme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
    }

    // MARK: - Average content (original view)

    private var averageContent: some View {
        VStack(spacing: 8) {
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
    }

    // MARK: - Bar chart content

    private var chartContent: some View {
        let today = Calendar.current.startOfDay(for: .now)
        let pastOrTodayData = dailyData.filter { $0.date <= today }
        let maxCalories = max(
            pastOrTodayData.map(\.calories).max() ?? 0,
            Double(target)
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
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 10))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
                    .font(.system(size: 10))
            }
        }
        .chartYScale(domain: 0 ... (maxCalories * 1.15))
        .chartXScale(domain: dailyData.first!.date ... dailyData.last!.date)
        .frame(height: 180)
        .padding(.top, 4)
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
