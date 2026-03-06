import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "flame.fill", value: 0) {
                TodayView()
            }

            Tab("History", systemImage: "chart.bar.fill", value: 1) {
                HistoryView()
            }

            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                SettingsView()
            }
        }
        .tint(CalorynTheme.sage)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}
