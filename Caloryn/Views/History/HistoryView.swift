import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query private var allEntries: [FoodLogEntry]
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]

    @State private var selectedRange: HistoryRange = .week

    private var profile: UserProfile? { profiles.first }

    private var dates: [Date] {
        Date.datesInRange(from: .now, days: selectedRange.days)
    }

    private var dailyTarget: Int {
        profile?.dailyCalorieTarget ?? 2000
    }

    private var currentWeekDays: [Date] {
        Date.datesForCurrentWeek()
    }

    private var currentWeekDailyTotals: [(date: Date, calories: Double)] {
        currentWeekDays.map { date in
            let total = entriesForDate(date).reduce(0.0) { $0 + $1.calories }
            return (date: date, calories: total)
        }
    }

    private var weeklyAverage: Double {
        let totals = currentWeekDailyTotals.map(\.calories)
        let daysWithFood = totals.filter { $0 > 0 }
        guard !daysWithFood.isEmpty else { return 0 }
        return daysWithFood.reduce(0, +) / Double(daysWithFood.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CalorynTheme.cardSpacing) {
                    WeeklyAverageCard(
                        average: weeklyAverage,
                        target: dailyTarget,
                        dailyData: currentWeekDailyTotals
                    )

                    rangePicker

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
                .padding(.horizontal, CalorynTheme.pagePadding)
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
    case twoWeeks
    case month

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: 7
        case .twoWeeks: 14
        case .month: 30
        }
    }

    var label: String {
        switch self {
        case .week: "7 Days"
        case .twoWeeks: "14 Days"
        case .month: "30 Days"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, FoodItem.self, FoodLogEntry.self, configurations: config)
    let context = ModelContext(container)

    let profile = UserProfile(age: 30, sex: .male, heightCm: 175, weightKg: 70, activityLevel: .moderatelyActive, dailyCalorieTarget: 2000)
    context.insert(profile)

    let oatmeal = FoodItem(name: "Oatmeal", caloriesPer100g: 389, proteinPer100g: 16.9, carbsPer100g: 66.3, fatPer100g: 6.9)
    let chicken = FoodItem(name: "Chicken Breast", caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6)
    let rice = FoodItem(name: "White Rice", caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3)
    let apple = FoodItem(name: "Apple", caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2)
    [oatmeal, chicken, rice, apple].forEach { context.insert($0) }

    let calendar = Calendar.current
    // Vary daily totals: ~1800–2300 so weekly average and day rows show meaningful data
    let dailyCalorieTargets: [Double] = [2150, 1880, 1200, 1650, 1950, 2320, 1780, 2050, 1900, 1180]
    let mealPortions: [(FoodItem, MealType, Double)] = [
        (oatmeal, .breakfast, 80),
        (apple, .breakfast, 120),
        (chicken, .lunch, 180),
        (rice, .lunch, 120),
        (chicken, .dinner, 150),
        (rice, .dinner, 100),
        (apple, .snack, 150),
    ]
    let baseTotal = mealPortions.reduce(0.0) { sum, item in sum + item.0.calories(forGrams: item.2) }

    for dayOffset in 0..<30 {
        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
        let dayStart = calendar.startOfDay(for: date)
        let target = dailyCalorieTargets[dayOffset % dailyCalorieTargets.count]
        let scale = target / baseTotal

        for (food, meal, grams) in mealPortions {
            let entry = FoodLogEntry(date: dayStart, mealType: meal, foodItem: food, portionGrams: grams * scale)
            context.insert(entry)
        }
    }

    try? context.save()

    return HistoryView()
        .modelContainer(container)
}
