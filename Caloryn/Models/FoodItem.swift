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
    var fiberPer100g: Double = 0
    var sugarsPer100g: Double?
    var addedSugarsPer100g: Double?
    var sucrosePer100g: Double?
    var glucosePer100g: Double?
    var fructosePer100g: Double?
    var lactosePer100g: Double?
    var maltosePer100g: Double?
    var maltodextrinsPer100g: Double?
    var starchPer100g: Double?
    var polyolsPer100g: Double?
    var saturatedFatPer100g: Double?
    var transFatPer100g: Double?
    var monounsaturatedFatPer100g: Double?
    var polyunsaturatedFatPer100g: Double?
    var omega3FatPer100g: Double?
    var omega6FatPer100g: Double?
    var omega9FatPer100g: Double?
    var saltPer100g: Double?
    var sodiumPer100g: Double?
    var cholesterolPer100g: Double?
    var solubleFiberPer100g: Double?
    var insolubleFiberPer100g: Double?
    var caseinPer100g: Double?
    var serumProteinsPer100g: Double?
    var alcoholPer100g: Double?

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
        fiberPer100g: Double = 0,
        sugarsPer100g: Double? = nil,
        addedSugarsPer100g: Double? = nil,
        sucrosePer100g: Double? = nil,
        glucosePer100g: Double? = nil,
        fructosePer100g: Double? = nil,
        lactosePer100g: Double? = nil,
        maltosePer100g: Double? = nil,
        maltodextrinsPer100g: Double? = nil,
        starchPer100g: Double? = nil,
        polyolsPer100g: Double? = nil,
        saturatedFatPer100g: Double? = nil,
        transFatPer100g: Double? = nil,
        monounsaturatedFatPer100g: Double? = nil,
        polyunsaturatedFatPer100g: Double? = nil,
        omega3FatPer100g: Double? = nil,
        omega6FatPer100g: Double? = nil,
        omega9FatPer100g: Double? = nil,
        saltPer100g: Double? = nil,
        sodiumPer100g: Double? = nil,
        cholesterolPer100g: Double? = nil,
        solubleFiberPer100g: Double? = nil,
        insolubleFiberPer100g: Double? = nil,
        caseinPer100g: Double? = nil,
        serumProteinsPer100g: Double? = nil,
        alcoholPer100g: Double? = nil,
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
        self.fiberPer100g = fiberPer100g
        self.sugarsPer100g = sugarsPer100g
        self.addedSugarsPer100g = addedSugarsPer100g
        self.sucrosePer100g = sucrosePer100g
        self.glucosePer100g = glucosePer100g
        self.fructosePer100g = fructosePer100g
        self.lactosePer100g = lactosePer100g
        self.maltosePer100g = maltosePer100g
        self.maltodextrinsPer100g = maltodextrinsPer100g
        self.starchPer100g = starchPer100g
        self.polyolsPer100g = polyolsPer100g
        self.saturatedFatPer100g = saturatedFatPer100g
        self.transFatPer100g = transFatPer100g
        self.monounsaturatedFatPer100g = monounsaturatedFatPer100g
        self.polyunsaturatedFatPer100g = polyunsaturatedFatPer100g
        self.omega3FatPer100g = omega3FatPer100g
        self.omega6FatPer100g = omega6FatPer100g
        self.omega9FatPer100g = omega9FatPer100g
        self.saltPer100g = saltPer100g
        self.sodiumPer100g = sodiumPer100g
        self.cholesterolPer100g = cholesterolPer100g
        self.solubleFiberPer100g = solubleFiberPer100g
        self.insolubleFiberPer100g = insolubleFiberPer100g
        self.caseinPer100g = caseinPer100g
        self.serumProteinsPer100g = serumProteinsPer100g
        self.alcoholPer100g = alcoholPer100g
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

    func fiber(forGrams grams: Double) -> Double {
        fiberPer100g * grams / 100
    }

    func sugars(forGrams grams: Double) -> Double? { scaled(sugarsPer100g, forGrams: grams) }
    func addedSugars(forGrams grams: Double) -> Double? { scaled(addedSugarsPer100g, forGrams: grams) }
    func sucrose(forGrams grams: Double) -> Double? { scaled(sucrosePer100g, forGrams: grams) }
    func glucose(forGrams grams: Double) -> Double? { scaled(glucosePer100g, forGrams: grams) }
    func fructose(forGrams grams: Double) -> Double? { scaled(fructosePer100g, forGrams: grams) }
    func lactose(forGrams grams: Double) -> Double? { scaled(lactosePer100g, forGrams: grams) }
    func maltose(forGrams grams: Double) -> Double? { scaled(maltosePer100g, forGrams: grams) }
    func maltodextrins(forGrams grams: Double) -> Double? { scaled(maltodextrinsPer100g, forGrams: grams) }
    func starch(forGrams grams: Double) -> Double? { scaled(starchPer100g, forGrams: grams) }
    func polyols(forGrams grams: Double) -> Double? { scaled(polyolsPer100g, forGrams: grams) }
    func saturatedFat(forGrams grams: Double) -> Double? { scaled(saturatedFatPer100g, forGrams: grams) }
    func transFat(forGrams grams: Double) -> Double? { scaled(transFatPer100g, forGrams: grams) }
    func monounsaturatedFat(forGrams grams: Double) -> Double? { scaled(monounsaturatedFatPer100g, forGrams: grams) }
    func polyunsaturatedFat(forGrams grams: Double) -> Double? { scaled(polyunsaturatedFatPer100g, forGrams: grams) }
    func omega3Fat(forGrams grams: Double) -> Double? { scaled(omega3FatPer100g, forGrams: grams) }
    func omega6Fat(forGrams grams: Double) -> Double? { scaled(omega6FatPer100g, forGrams: grams) }
    func omega9Fat(forGrams grams: Double) -> Double? { scaled(omega9FatPer100g, forGrams: grams) }
    func salt(forGrams grams: Double) -> Double? { scaled(saltPer100g, forGrams: grams) }
    func sodium(forGrams grams: Double) -> Double? { scaled(sodiumPer100g, forGrams: grams) }
    func cholesterol(forGrams grams: Double) -> Double? { scaled(cholesterolPer100g, forGrams: grams) }
    func solubleFiber(forGrams grams: Double) -> Double? { scaled(solubleFiberPer100g, forGrams: grams) }
    func insolubleFiber(forGrams grams: Double) -> Double? { scaled(insolubleFiberPer100g, forGrams: grams) }
    func casein(forGrams grams: Double) -> Double? { scaled(caseinPer100g, forGrams: grams) }
    func serumProteins(forGrams grams: Double) -> Double? { scaled(serumProteinsPer100g, forGrams: grams) }
    func alcohol(forGrams grams: Double) -> Double? { scaled(alcoholPer100g, forGrams: grams) }

    func updateRecipeNutritionFromIngredients() {
        let ingredients = recipeIngredients ?? []
        let totalGrams = ingredients.reduce(0) { $0 + $1.portionGrams }

        guard totalGrams > 0 else {
            caloriesPer100g = 0
            proteinPer100g = 0
            carbsPer100g = 0
            fatPer100g = 0
            fiberPer100g = 0
            sugarsPer100g = nil
            addedSugarsPer100g = nil
            sucrosePer100g = nil
            glucosePer100g = nil
            fructosePer100g = nil
            lactosePer100g = nil
            maltosePer100g = nil
            maltodextrinsPer100g = nil
            starchPer100g = nil
            polyolsPer100g = nil
            saturatedFatPer100g = nil
            transFatPer100g = nil
            monounsaturatedFatPer100g = nil
            polyunsaturatedFatPer100g = nil
            omega3FatPer100g = nil
            omega6FatPer100g = nil
            omega9FatPer100g = nil
            saltPer100g = nil
            sodiumPer100g = nil
            cholesterolPer100g = nil
            solubleFiberPer100g = nil
            insolubleFiberPer100g = nil
            caseinPer100g = nil
            serumProteinsPer100g = nil
            alcoholPer100g = nil
            defaultServingG = nil
            servingDescription = nil
            return
        }

        caloriesPer100g = ingredients.reduce(0) { $0 + $1.calories } / totalGrams * 100
        proteinPer100g = ingredients.reduce(0) { $0 + $1.proteinG } / totalGrams * 100
        carbsPer100g = ingredients.reduce(0) { $0 + $1.carbsG } / totalGrams * 100
        fatPer100g = ingredients.reduce(0) { $0 + $1.fatG } / totalGrams * 100
        fiberPer100g = ingredients.reduce(0) { $0 + $1.fiberG } / totalGrams * 100
        sugarsPer100g = aggregatePer100g(ingredients.map(\.sugarsG), totalGrams: totalGrams)
        addedSugarsPer100g = aggregatePer100g(ingredients.map(\.addedSugarsG), totalGrams: totalGrams)
        sucrosePer100g = aggregatePer100g(ingredients.map(\.sucroseG), totalGrams: totalGrams)
        glucosePer100g = aggregatePer100g(ingredients.map(\.glucoseG), totalGrams: totalGrams)
        fructosePer100g = aggregatePer100g(ingredients.map(\.fructoseG), totalGrams: totalGrams)
        lactosePer100g = aggregatePer100g(ingredients.map(\.lactoseG), totalGrams: totalGrams)
        maltosePer100g = aggregatePer100g(ingredients.map(\.maltoseG), totalGrams: totalGrams)
        maltodextrinsPer100g = aggregatePer100g(ingredients.map(\.maltodextrinsG), totalGrams: totalGrams)
        starchPer100g = aggregatePer100g(ingredients.map(\.starchG), totalGrams: totalGrams)
        polyolsPer100g = aggregatePer100g(ingredients.map(\.polyolsG), totalGrams: totalGrams)
        saturatedFatPer100g = aggregatePer100g(ingredients.map(\.saturatedFatG), totalGrams: totalGrams)
        transFatPer100g = aggregatePer100g(ingredients.map(\.transFatG), totalGrams: totalGrams)
        monounsaturatedFatPer100g = aggregatePer100g(ingredients.map(\.monounsaturatedFatG), totalGrams: totalGrams)
        polyunsaturatedFatPer100g = aggregatePer100g(ingredients.map(\.polyunsaturatedFatG), totalGrams: totalGrams)
        omega3FatPer100g = aggregatePer100g(ingredients.map(\.omega3FatG), totalGrams: totalGrams)
        omega6FatPer100g = aggregatePer100g(ingredients.map(\.omega6FatG), totalGrams: totalGrams)
        omega9FatPer100g = aggregatePer100g(ingredients.map(\.omega9FatG), totalGrams: totalGrams)
        saltPer100g = aggregatePer100g(ingredients.map(\.saltG), totalGrams: totalGrams)
        sodiumPer100g = aggregatePer100g(ingredients.map(\.sodiumG), totalGrams: totalGrams)
        cholesterolPer100g = aggregatePer100g(ingredients.map(\.cholesterolG), totalGrams: totalGrams)
        solubleFiberPer100g = aggregatePer100g(ingredients.map(\.solubleFiberG), totalGrams: totalGrams)
        insolubleFiberPer100g = aggregatePer100g(ingredients.map(\.insolubleFiberG), totalGrams: totalGrams)
        caseinPer100g = aggregatePer100g(ingredients.map(\.caseinG), totalGrams: totalGrams)
        serumProteinsPer100g = aggregatePer100g(ingredients.map(\.serumProteinsG), totalGrams: totalGrams)
        alcoholPer100g = aggregatePer100g(ingredients.map(\.alcoholG), totalGrams: totalGrams)
        defaultServingG = totalGrams
        servingDescription = nil
        isRecipe = true
        isCustom = false
        nutriscoreGrade = nil
    }

    private func scaled(_ value: Double?, forGrams grams: Double) -> Double? {
        value.map { $0 * grams / 100 }
    }

    private func aggregatePer100g(_ values: [Double?], totalGrams: Double) -> Double? {
        guard values.contains(where: { $0 != nil }) else { return nil }
        return values.reduce(0) { $0 + ($1 ?? 0) } / totalGrams * 100
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
