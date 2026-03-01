import SwiftUI

struct MacroProgressView: View {
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let proteinTarget: Double
    let carbTarget: Double
    let fatTarget: Double

    var body: some View {
        HStack(spacing: 20) {
            MacroBar(
                label: "Protein",
                current: proteinG,
                target: proteinTarget,
                color: BiteLogTheme.proteinColor
            )
            MacroBar(
                label: "Carbs",
                current: carbsG,
                target: carbTarget,
                color: BiteLogTheme.carbColor
            )
            MacroBar(
                label: "Fat",
                current: fatG,
                target: fatTarget,
                color: BiteLogTheme.fatColor
            )
        }
        .padding(.vertical, 4)
    }
}

private struct MacroBar: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                        .animation(.smooth(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())

            Text("\(current.macroFormatted) / \(target.macroFormatted)")
                .font(BiteLogTheme.numericCaption)
                .foregroundStyle(BiteLogTheme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(current.macroFormatted) of \(target.macroFormatted)")
    }
}

#Preview {
    MacroProgressView(
        proteinG: 80, carbsG: 150, fatG: 40,
        proteinTarget: 120, carbTarget: 200, fatTarget: 65
    )
    .padding()
}
