import SwiftUI
import UIKit

enum BiteLogTheme {
    // MARK: - Colors

    static let sage = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.588, green: 0.671, blue: 0.514, alpha: 1)   // #96AB83
            : UIColor(red: 0.486, green: 0.557, blue: 0.420, alpha: 1)   // #7C8E6B
    })

    static let stone = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.784, green: 0.733, blue: 0.686, alpha: 1)   // #C8BBAF
            : UIColor(red: 0.710, green: 0.659, blue: 0.596, alpha: 1)   // #B5A898
    })

    static let terracotta = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.831, green: 0.565, blue: 0.435, alpha: 1)   // #D4906F
            : UIColor(red: 0.757, green: 0.471, blue: 0.337, alpha: 1)   // #C17856
    })

    static let warmWhite = Color(red: 0.980, green: 0.980, blue: 0.969)  // #FAFAF7

    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.153, green: 0.149, blue: 0.141, alpha: 1)   // #272624
            : UIColor(red: 0.953, green: 0.945, blue: 0.925, alpha: 1)   // #F3F1EC
    })

    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.925, green: 0.922, blue: 0.910, alpha: 1)   // #ECEBE8
            : UIColor(red: 0.173, green: 0.173, blue: 0.165, alpha: 1)   // #2C2C2A
    })

    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.678, green: 0.675, blue: 0.659, alpha: 1)   // #ADACA8
            : UIColor(red: 0.541, green: 0.541, blue: 0.522, alpha: 1)   // #8A8A85
    })

    static let proteinColor = sage

    static let carbColor = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.659, green: 0.769, blue: 0.851, alpha: 1)   // #A8C4D9
            : UIColor(red: 0.588, green: 0.694, blue: 0.776, alpha: 1)   // #96B1C6
    })

    static let fatColor = terracotta

    // MARK: - Spacing

    static let pagePadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12

    // MARK: - Typography

    static let largeNumber: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    static let sectionTitle: Font = .system(.title2, weight: .semibold)
    static let itemTitle: Font = .system(.headline)
    static let bodyText: Font = .system(.body)
    static let caption: Font = .system(.caption, weight: .medium)
    static let numericBody: Font = .system(.body, design: .rounded, weight: .medium)
    static let numericCaption: Font = .system(.caption, design: .rounded, weight: .semibold)
}
