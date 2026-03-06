import Foundation
import SwiftData

@Model
final class FoodLogEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var mealType: MealType = MealType.breakfast
    var snackIndex: Int = 0

    var foodItem: FoodItem?

    var portionGrams: Double = 0
    var calories: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0

    var foodName: String = ""

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
