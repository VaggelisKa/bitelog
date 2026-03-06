import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable, Hashable {
    case welcome
    case personalInfo
    case activityLevel
    case goalSummary
    case macroRatios
}

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @State private var path: [OnboardingStep] = []

    @State private var age: Int = 30
    @State private var sex: Sex = .male
    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 75
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var calorieDeficit: Double = 500
    @State private var finalCalorieTarget: Int = 2000
    @State private var proteinRatio: Double = 0.30
    @State private var carbRatio: Double = 0.40
    @State private var fatRatio: Double = 0.30

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
                        calorieDeficit: $calorieDeficit
                    ) { target in
                        finalCalorieTarget = target
                        path.append(.macroRatios)
                    }
                case .macroRatios:
                    MacroRatioStepView(
                        calorieTarget: finalCalorieTarget,
                        proteinRatio: $proteinRatio,
                        carbRatio: $carbRatio,
                        fatRatio: $fatRatio,
                        onComplete: saveProfile
                    )
                }
            }
        }
    }

    private func saveProfile() {
        let computedBmr = NutritionCalculator.bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age)
        let computedTdee = NutritionCalculator.tdee(bmr: computedBmr, activity: activityLevel)

        if let profile = profiles.first {
            profile.age = age
            profile.sex = sex
            profile.heightCm = heightCm
            profile.weightKg = weightKg
            profile.activityLevel = activityLevel
            profile.manualOverride = false
            profile.calorieDeficit = calorieDeficit
            profile.bmr = computedBmr
            profile.tdee = computedTdee
            profile.dailyCalorieTarget = finalCalorieTarget
            profile.proteinTargetG = NutritionCalculator.macroGrams(calories: Double(finalCalorieTarget), ratio: proteinRatio, caloriesPerGram: 4)
            profile.carbTargetG = NutritionCalculator.macroGrams(calories: Double(finalCalorieTarget), ratio: carbRatio, caloriesPerGram: 4)
            profile.fatTargetG = NutritionCalculator.macroGrams(calories: Double(finalCalorieTarget), ratio: fatRatio, caloriesPerGram: 9)
            profile.updatedAt = Date()
            return
        }

        let profile = UserProfile(
            age: age,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            dailyCalorieTarget: finalCalorieTarget,
            calorieDeficit: calorieDeficit,
            proteinRatio: proteinRatio,
            carbRatio: carbRatio,
            fatRatio: fatRatio
        )
        modelContext.insert(profile)
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
