import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var age: Int
    var sex: Sex
    var heightCm: Double
    var weightKg: Double
    var activityLevel: ActivityLevel

    var bmr: Double
    var tdee: Double
    var dailyCalorieTarget: Int
    var manualOverride: Bool

    var proteinTargetG: Double
    var carbTargetG: Double
    var fatTargetG: Double

    var createdAt: Date
    var updatedAt: Date

    init(
        age: Int,
        sex: Sex,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel,
        dailyCalorieTarget: Int? = nil,
        manualOverride: Bool = false,
        proteinRatio: Double = 0.30,
        carbRatio: Double = 0.40,
        fatRatio: Double = 0.30
    ) {
        self.id = UUID()
        self.age = age
        self.sex = sex
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevel = activityLevel
        self.manualOverride = manualOverride
        self.createdAt = Date()
        self.updatedAt = Date()

        let computedBmr = NutritionCalculator.bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age)
        let computedTdee = NutritionCalculator.tdee(bmr: computedBmr, activity: activityLevel)
        let target = dailyCalorieTarget ?? Int(max(1200, computedTdee - 500))

        self.bmr = computedBmr
        self.tdee = computedTdee
        self.dailyCalorieTarget = target
        self.proteinTargetG = NutritionCalculator.macroGrams(calories: Double(target), ratio: proteinRatio, caloriesPerGram: 4)
        self.carbTargetG = NutritionCalculator.macroGrams(calories: Double(target), ratio: carbRatio, caloriesPerGram: 4)
        self.fatTargetG = NutritionCalculator.macroGrams(calories: Double(target), ratio: fatRatio, caloriesPerGram: 9)
    }

    func recalculate(proteinRatio: Double = 0.30, carbRatio: Double = 0.40, fatRatio: Double = 0.30) {
        bmr = NutritionCalculator.bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age)
        tdee = NutritionCalculator.tdee(bmr: bmr, activity: activityLevel)
        if !manualOverride {
            dailyCalorieTarget = Int(tdee - 500)
        }
        proteinTargetG = NutritionCalculator.macroGrams(calories: Double(dailyCalorieTarget), ratio: proteinRatio, caloriesPerGram: 4)
        carbTargetG = NutritionCalculator.macroGrams(calories: Double(dailyCalorieTarget), ratio: carbRatio, caloriesPerGram: 4)
        fatTargetG = NutritionCalculator.macroGrams(calories: Double(dailyCalorieTarget), ratio: fatRatio, caloriesPerGram: 9)
        updatedAt = Date()
    }
}
