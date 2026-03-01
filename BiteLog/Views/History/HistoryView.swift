import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query private var allEntries: [FoodLogEntry]
    @Query private var profiles: [UserProfile]

    @State private var selectedRange: HistoryRange = .week

    private var profile: UserProfile? { profiles.first }

    private var dates: [Date] {
        Date.datesInRange(from: .now, days: selectedRange.days)
    }

    private var dailyTarget: Int {
        profile?.dailyCalorieTarget ?? 2000
    }

    private var weeklyAverage: Double {
        let last7 = Date.datesInRange(from: .now, days: 7)
        let totals = last7.map { date in
            entriesForDate(date).reduce(0.0) { $0 + $1.calories }
        }
        let daysWithFood = totals.filter { $0 > 0 }
        guard !daysWithFood.isEmpty else { return 0 }
        return daysWithFood.reduce(0, +) / Double(daysWithFood.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BiteLogTheme.cardSpacing) {
                    rangePicker

                    WeeklyAverageCard(
                        average: weeklyAverage,
                        target: dailyTarget
                    )

                    LazyVStack(spacing: 10) {
                        ForEach(dates, id: \.self) { date in
                            let dayEntries = entriesForDate(date)
                            let total = dayEntries.reduce(0.0) { $0 + $1.calories }
                            DaySummaryRow(
                                date: date,
                                totalCalories: total,
                                target: dailyTarget,
                                entryCount: dayEntries.count
                            )
                        }
                    }
                }
                .padding(.horizontal, BiteLogTheme.pagePadding)
                .padding(.bottom, 20)
            }
            .navigationTitle("History")
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(HistoryRange.allCases) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)
    }

    private func entriesForDate(_ date: Date) -> [FoodLogEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

enum HistoryRange: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        }
    }

    var label: String {
        switch self {
        case .week: "7 Days"
        case .month: "30 Days"
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}
