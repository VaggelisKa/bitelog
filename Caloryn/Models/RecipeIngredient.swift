import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    var id: UUID = UUID()
    var name: String = ""
    var brand: String?
    var portionGrams: Double = 0

    var caloriesPer100g: Double = 0
    var proteinPer100g: Double = 0
    var carbsPer100g: Double = 0
    var fatPer100g: Double = 0

    var sortOrder: Int = 0
    var createdAt: Date = Date()

    var recipe: FoodItem?

    init(
        name: String,
        brand: String? = nil,
        portionGrams: Double,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        sortOrder: Int
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.portionGrams = portionGrams
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    convenience init(from foodItem: FoodItem, portionGrams: Double, sortOrder: Int) {
        self.init(
            name: foodItem.name,
            brand: foodItem.brand,
            portionGrams: portionGrams,
            caloriesPer100g: foodItem.caloriesPer100g,
            proteinPer100g: foodItem.proteinPer100g,
            carbsPer100g: foodItem.carbsPer100g,
            fatPer100g: foodItem.fatPer100g,
            sortOrder: sortOrder
        )
    }

    var calories: Double {
        caloriesPer100g * portionGrams / 100
    }

    var proteinG: Double {
        proteinPer100g * portionGrams / 100
    }

    var carbsG: Double {
        carbsPer100g * portionGrams / 100
    }

    var fatG: Double {
        fatPer100g * portionGrams / 100
    }
}
