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
    var produceKindRaw: String?

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
        sortOrder: Int,
        produceKind: ProduceKind = .unclassified
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.portionGrams = portionGrams
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
        self.sortOrder = sortOrder
        self.produceKindRaw = produceKind.rawValue
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
            fiberPer100g: foodItem.fiberPer100g,
            sugarsPer100g: foodItem.sugarsPer100g,
            addedSugarsPer100g: foodItem.addedSugarsPer100g,
            sucrosePer100g: foodItem.sucrosePer100g,
            glucosePer100g: foodItem.glucosePer100g,
            fructosePer100g: foodItem.fructosePer100g,
            lactosePer100g: foodItem.lactosePer100g,
            maltosePer100g: foodItem.maltosePer100g,
            maltodextrinsPer100g: foodItem.maltodextrinsPer100g,
            starchPer100g: foodItem.starchPer100g,
            polyolsPer100g: foodItem.polyolsPer100g,
            saturatedFatPer100g: foodItem.saturatedFatPer100g,
            transFatPer100g: foodItem.transFatPer100g,
            monounsaturatedFatPer100g: foodItem.monounsaturatedFatPer100g,
            polyunsaturatedFatPer100g: foodItem.polyunsaturatedFatPer100g,
            omega3FatPer100g: foodItem.omega3FatPer100g,
            omega6FatPer100g: foodItem.omega6FatPer100g,
            omega9FatPer100g: foodItem.omega9FatPer100g,
            saltPer100g: foodItem.saltPer100g,
            sodiumPer100g: foodItem.sodiumPer100g,
            cholesterolPer100g: foodItem.cholesterolPer100g,
            solubleFiberPer100g: foodItem.solubleFiberPer100g,
            insolubleFiberPer100g: foodItem.insolubleFiberPer100g,
            caseinPer100g: foodItem.caseinPer100g,
            serumProteinsPer100g: foodItem.serumProteinsPer100g,
            alcoholPer100g: foodItem.alcoholPer100g,
            sortOrder: sortOrder,
            produceKind: foodItem.produceKind
        )
    }

    var produceKind: ProduceKind {
        get {
            ProduceKind(rawValue: produceKindRaw ?? "") ?? .unclassified
        }
        set {
            produceKindRaw = newValue.rawValue
        }
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

    var fiberG: Double {
        fiberPer100g * portionGrams / 100
    }

    var sugarsG: Double? { scaled(sugarsPer100g) }
    var addedSugarsG: Double? { scaled(addedSugarsPer100g) }
    var sucroseG: Double? { scaled(sucrosePer100g) }
    var glucoseG: Double? { scaled(glucosePer100g) }
    var fructoseG: Double? { scaled(fructosePer100g) }
    var lactoseG: Double? { scaled(lactosePer100g) }
    var maltoseG: Double? { scaled(maltosePer100g) }
    var maltodextrinsG: Double? { scaled(maltodextrinsPer100g) }
    var starchG: Double? { scaled(starchPer100g) }
    var polyolsG: Double? { scaled(polyolsPer100g) }
    var saturatedFatG: Double? { scaled(saturatedFatPer100g) }
    var transFatG: Double? { scaled(transFatPer100g) }
    var monounsaturatedFatG: Double? { scaled(monounsaturatedFatPer100g) }
    var polyunsaturatedFatG: Double? { scaled(polyunsaturatedFatPer100g) }
    var omega3FatG: Double? { scaled(omega3FatPer100g) }
    var omega6FatG: Double? { scaled(omega6FatPer100g) }
    var omega9FatG: Double? { scaled(omega9FatPer100g) }
    var saltG: Double? { scaled(saltPer100g) }
    var sodiumG: Double? { scaled(sodiumPer100g) }
    var cholesterolG: Double? { scaled(cholesterolPer100g) }
    var solubleFiberG: Double? { scaled(solubleFiberPer100g) }
    var insolubleFiberG: Double? { scaled(insolubleFiberPer100g) }
    var caseinG: Double? { scaled(caseinPer100g) }
    var serumProteinsG: Double? { scaled(serumProteinsPer100g) }
    var alcoholG: Double? { scaled(alcoholPer100g) }

    private func scaled(_ value: Double?) -> Double? {
        value.map { $0 * portionGrams / 100 }
    }
}
