import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID = UUID()
    var barcode: String?
    var name: String = ""
    var brand: String?

    var caloriesPer100g: Double = 0
    var proteinPer100g: Double = 0
    var carbsPer100g: Double = 0
    var fatPer100g: Double = 0

    var nutriscoreGrade: String?

    var defaultServingG: Double?
    var servingDescription: String?

    var isCustom: Bool = false

    var lastUsed: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \FoodLogEntry.foodItem)
    var logEntries: [FoodLogEntry]?

    init(
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        defaultServingG: Double? = nil,
        servingDescription: String? = nil,
        nutriscoreGrade: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.defaultServingG = defaultServingG
        self.servingDescription = servingDescription
        self.nutriscoreGrade = nutriscoreGrade
        self.isCustom = isCustom
        self.lastUsed = Date()
    }

    func calories(forGrams grams: Double) -> Double {
        caloriesPer100g * grams / 100
    }

    func protein(forGrams grams: Double) -> Double {
        proteinPer100g * grams / 100
    }

    func carbs(forGrams grams: Double) -> Double {
        carbsPer100g * grams / 100
    }

    func fat(forGrams grams: Double) -> Double {
        fatPer100g * grams / 100
    }
}
