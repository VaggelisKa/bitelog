import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable, Hashable {
    case welcome
    case personalInfo
    case activityLevel
    case goalSummary
}

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path: [OnboardingStep] = []

    @State private var age: Int = 30
    @State private var sex: Sex = .male
    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 75
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var calorieDeficit: Double = 500

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeStepView {
                path.append(.personalInfo)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .welcome:
                    EmptyView()
                case .personalInfo:
                    PersonalInfoStepView(
                        age: $age,
                        sex: $sex,
                        heightCm: $heightCm,
                        weightKg: $weightKg
                    ) {
                        path.append(.activityLevel)
                    }
                case .activityLevel:
                    ActivityLevelStepView(activityLevel: $activityLevel) {
                        path.append(.goalSummary)
                    }
                case .goalSummary:
                    GoalSummaryStepView(
                        age: age,
                        sex: sex,
                        heightCm: heightCm,
                        weightKg: weightKg,
                        activityLevel: activityLevel,
                        calorieDeficit: $calorieDeficit,
                        onComplete: saveProfile
                    )
                }
            }
        }
    }

    private func saveProfile() {
        let bmr = NutritionCalculator.bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age)
        let tdee = NutritionCalculator.tdee(bmr: bmr, activity: activityLevel)
        let target = NutritionCalculator.defaultTarget(tdee: tdee, deficit: calorieDeficit)

        let profile = UserProfile(
            age: age,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            dailyCalorieTarget: target
        )
        modelContext.insert(profile)
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
