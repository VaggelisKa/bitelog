import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]

    private var hasCompletedOnboarding: Bool {
        !profiles.isEmpty
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingContainerView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.4), value: hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self], inMemory: true)
}
