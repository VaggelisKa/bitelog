import SwiftUI

enum BiteLogTheme {
    // MARK: - Colors

    static let sage = Color(red: 0.486, green: 0.557, blue: 0.420)       // #7C8E6B
    static let stone = Color(red: 0.710, green: 0.659, blue: 0.596)      // #B5A898
    static let terracotta = Color(red: 0.757, green: 0.471, blue: 0.337) // #C17856
    static let warmWhite = Color(red: 0.980, green: 0.980, blue: 0.969)  // #FAFAF7
    static let surface = Color(red: 0.953, green: 0.945, blue: 0.925)    // #F3F1EC
    static let textPrimary = Color(red: 0.173, green: 0.173, blue: 0.165) // #2C2C2A
    static let textSecondary = Color(red: 0.541, green: 0.541, blue: 0.522) // #8A8A85

    static let proteinColor = sage
    static let carbColor = Color(red: 0.588, green: 0.694, blue: 0.776)  // Muted steel blue
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
