import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var allEntries: [FoodLogEntry]

    @State private var selectedDate: Date = Date().startOfDay
    @State private var showingFoodSearch = false
    @State private var selectedMealType: MealType = .breakfast

    @ScaledMetric private var ringSize: CGFloat = 180

    private var profile: UserProfile? { profiles.first }

    private var todayEntries: [FoodLogEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var totalCalories: Double {
        todayEntries.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        todayEntries.reduce(0) { $0 + $1.proteinG }
    }

    private var totalCarbs: Double {
        todayEntries.reduce(0) { $0 + $1.carbsG }
    }

    private var totalFat: Double {
        todayEntries.reduce(0) { $0 + $1.fatG }
    }

    private func entries(for meal: MealType) -> [FoodLogEntry] {
        todayEntries
            .filter { $0.mealType == meal }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BiteLogTheme.cardSpacing) {
                    dateNavigator

                    CalorieRingView(
                        consumed: totalCalories,
                        target: profile?.dailyCalorieTarget ?? 2000,
                        ringSize: ringSize
                    )

                    if let profile {
                        MacroProgressView(
                            proteinG: totalProtein,
                            carbsG: totalCarbs,
                            fatG: totalFat,
                            proteinTarget: profile.proteinTargetG,
                            carbTarget: profile.carbTargetG,
                            fatTarget: profile.fatTargetG
                        )
                        .padding(.horizontal, 4)
                    }

                    ForEach(MealType.allCases) { meal in
                        MealSectionView(
                            mealType: meal,
                            entries: entries(for: meal),
                            onAdd: {
                                selectedMealType = meal
                                showingFoodSearch = true
                            },
                            onDelete: { entry in
                                withAnimation {
                                    modelContext.delete(entry)
                                }
                            }
                        )
                    }

                    copyYesterdayButton
                }
                .padding(.horizontal, BiteLogTheme.pagePadding)
                .padding(.bottom, 20)
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView(mealType: selectedMealType, logDate: selectedDate)
            }
        }
    }

    private var dateNavigator: some View {
        HStack {
            Button {
                withAnimation {
                    selectedDate = selectedDate.yesterday
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(BiteLogTheme.sage)
            }
            .accessibilityLabel("Previous day")

            Spacer()

            Text(selectedDate.shortFormatted)
                .font(BiteLogTheme.sectionTitle)
                .foregroundStyle(BiteLogTheme.textPrimary)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                withAnimation {
                    selectedDate = selectedDate.tomorrow
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(selectedDate.isToday ? BiteLogTheme.textSecondary.opacity(0.3) : BiteLogTheme.sage)
            }
            .disabled(selectedDate.isToday)
            .accessibilityLabel("Next day")
        }
        .padding(.vertical, 8)
    }

    private var copyYesterdayButton: some View {
        let yesterdayEntries = allEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate.yesterday)
        }

        return Group {
            if todayEntries.isEmpty && !yesterdayEntries.isEmpty {
                Button {
                    withAnimation {
                        copyEntries(from: yesterdayEntries)
                    }
                } label: {
                    Label("Copy Yesterday's Meals", systemImage: "doc.on.doc")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                .tint(BiteLogTheme.sage)
            }
        }
    }

    private func copyEntries(from entries: [FoodLogEntry]) {
        for entry in entries {
            guard let food = entry.foodItem else { continue }
            let newEntry = FoodLogEntry(
                date: selectedDate,
                mealType: entry.mealType,
                foodItem: food,
                portionGrams: entry.portionGrams
            )
            modelContext.insert(newEntry)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}
