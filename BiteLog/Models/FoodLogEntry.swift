import Foundation
import SwiftData

@Model
final class FoodLogEntry {
    var id: UUID
    var date: Date
    var mealType: MealType
    var snackIndex: Int

    var foodItem: FoodItem?

    var portionGrams: Double
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    var foodName: String

    init(
        date: Date,
        mealType: MealType,
        foodItem: FoodItem,
        portionGrams: Double,
        snackIndex: Int = 1
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.mealType = mealType
        self.snackIndex = mealType == .snack ? snackIndex : 0
        self.foodItem = foodItem
        self.portionGrams = portionGrams
        self.calories = foodItem.calories(forGrams: portionGrams)
        self.proteinG = foodItem.protein(forGrams: portionGrams)
        self.carbsG = foodItem.carbs(forGrams: portionGrams)
        self.fatG = foodItem.fat(forGrams: portionGrams)
        self.foodName = foodItem.name
    }
}
