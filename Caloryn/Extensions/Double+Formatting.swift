import Foundation

extension Double {
    var kcalFormatted: String {
        "\(Int(self)) kcal"
    }

    var macroFormatted: String {
        let s = String(format: "%.1f", self)
        if s.hasSuffix(".0") {
            return "\(Int(self.rounded()))g"
        }
        return s + "g"
    }

    var wholeFormatted: String {
        "\(Int(self))"
    }
}

extension Int {
    var kcalFormatted: String {
        "\(self) kcal"
    }
}
