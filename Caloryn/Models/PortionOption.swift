import Foundation

struct PortionOption: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var gramsPerPortion: Double

    init(name: String, gramsPerPortion: Double) {
        self.id = UUID()
        self.name = name
        self.gramsPerPortion = gramsPerPortion
    }

    func label(quantity: Double) -> String {
        let formattedQty = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(quantity))"
            : String(format: "%.1f", quantity)
        return "\(formattedQty) \(name)"
    }
}
