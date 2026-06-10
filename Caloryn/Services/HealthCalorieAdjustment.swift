import Foundation

enum HealthCalorieAdjustment {
    static let activeEnergyCreditRatio = 0.70

    static func creditedCalories(from activeEnergyKcal: Double) -> Int {
        max(0, Int((activeEnergyKcal * activeEnergyCreditRatio).rounded()))
    }

    static func adjustedTarget(baseTarget: Int, activeEnergyKcal: Double, isEnabled: Bool) -> Int {
        guard isEnabled else { return baseTarget }
        return baseTarget + creditedCalories(from: activeEnergyKcal)
    }
}
