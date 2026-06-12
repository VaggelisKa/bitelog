import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = CalorynTheme.cornerRadius

    func body(content: Content) -> some View {
        content
            .padding(CalorynTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

struct GlassCircleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .circle)
    }
}

struct CalorynInputFieldModifier: ViewModifier {
    var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: .rect(cornerRadius: CalorynTheme.smallCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: CalorynTheme.smallCornerRadius, style: .continuous)
                    .stroke(
                        isFocused
                            ? CalorynTheme.sage.opacity(0.72)
                            : CalorynTheme.textSecondary.opacity(0.14),
                        lineWidth: isFocused ? 1.2 : 0.6
                    )
                    .allowsHitTesting(false)
            }
            .animation(.smooth(duration: 0.18), value: isFocused)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = CalorynTheme.cornerRadius) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glassCircle() -> some View {
        modifier(GlassCircleModifier())
    }

    func calorynInputField(isFocused: Bool = false) -> some View {
        modifier(CalorynInputFieldModifier(isFocused: isFocused))
    }
}
