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
    var isRecipe: Bool = false

    var lastUsed: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \FoodLogEntry.foodItem)
    var logEntries: [FoodLogEntry]?

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var recipeIngredients: [RecipeIngredient]?

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
        isCustom: Bool = false,
        isRecipe: Bool = false
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
        self.isRecipe = isRecipe
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

    func updateRecipeNutritionFromIngredients() {
        let ingredients = recipeIngredients ?? []
        let totalGrams = ingredients.reduce(0) { $0 + $1.portionGrams }

        guard totalGrams > 0 else {
            caloriesPer100g = 0
            proteinPer100g = 0
            carbsPer100g = 0
            fatPer100g = 0
            defaultServingG = nil
            servingDescription = nil
            return
        }

        caloriesPer100g = ingredients.reduce(0) { $0 + $1.calories } / totalGrams * 100
        proteinPer100g = ingredients.reduce(0) { $0 + $1.proteinG } / totalGrams * 100
        carbsPer100g = ingredients.reduce(0) { $0 + $1.carbsG } / totalGrams * 100
        fatPer100g = ingredients.reduce(0) { $0 + $1.fatG } / totalGrams * 100
        defaultServingG = totalGrams
        servingDescription = nil
        isRecipe = true
        isCustom = false
        nutriscoreGrade = nil
    }

    var servingInfo: ServingInfo? {
        guard let description = servingDescription,
              let gramsTotal = defaultServingG,
              gramsTotal > 0 else { return nil }

        let excludedUnits: Set<String> = [
            "g", "gr", "gram", "grams", "gramos",
            "ml", "milliliter", "milliliters", "millilitres",
            "kg", "kilogram", "kilograms",
            "l", "liter", "liters", "litre", "litres",
            "oz", "ounce", "ounces", "fl",
            "lb", "pound", "pounds",
            "cl", "dl", "serving", "portion"
        ]

        guard let match = description.wholeMatch(
            of: /^\s*(\d+(?:[.,]\d+)?)\s+(.+?)(?:\s*\(.*\))?\s*$/
        ) else { return nil }

        let countStr = String(match.1).replacingOccurrences(of: ",", with: ".")
        guard let count = Double(countStr), count > 0 else { return nil }

        let unit = String(match.2).trimmingCharacters(in: .whitespaces).lowercased()
        guard !unit.isEmpty, !excludedUnits.contains(unit) else { return nil }

        let gramsPerUnit = gramsTotal / count
        guard gramsPerUnit >= 1 else { return nil }

        let singular: String
        let plural: String
        if unit.hasSuffix("ies") {
            singular = String(unit.dropLast(3)) + "y"
            plural = unit
        } else if unit.hasSuffix("ches") || unit.hasSuffix("shes")
                    || unit.hasSuffix("ses") || unit.hasSuffix("xes")
                    || unit.hasSuffix("zes") {
            singular = String(unit.dropLast(2))
            plural = unit
        } else if unit.hasSuffix("s") && !unit.hasSuffix("ss") {
            singular = String(unit.dropLast())
            plural = unit
        } else {
            singular = unit
            plural = unit + "s"
        }

        return ServingInfo(unitName: singular, gramsPerUnit: gramsPerUnit, pluralName: plural)
    }
}

struct ServingInfo {
    let unitName: String
    let gramsPerUnit: Double
    let pluralName: String

    func label(for count: Int) -> String {
        count == 1 ? "1 \(unitName)" : "\(count) \(pluralName)"
    }
}
