import Foundation

extension Double {
    var kcalFormatted: String {
        "\(Int(self)) kcal"
    }

    var macroFormatted: String {
        String(format: "%.1fg", self)
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
