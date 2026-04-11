import SwiftUI

struct CalorieRingView: View {
    let consumed: Double
    let target: Int
    let ringSize: CGFloat

    @ScaledMetric private var numberSize: CGFloat = 44
    @State private var animatedRingProgress: Double = 0

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / Double(target), 1.5)
    }

    private var displayedRingProgress: Double {
        min(progress, 1.0)
    }

    private var remaining: Int {
        max(0, target - Int(consumed))
    }

    private var overAmount: Int {
        max(0, Int(consumed) - target)
    }

    private var isOver: Bool {
        consumed > Double(target)
    }

    private var consumedDisplay: Int {
        Int(consumed.rounded(.towardZero))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    CalorynTheme.sage.opacity(0.15),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedRingProgress)
                .stroke(
                    isOver ? CalorynTheme.terracotta : CalorynTheme.sage,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(animatedRingProgress < 0.01 ? 0 : 1)

            VStack(spacing: 4) {
                Text("\(consumedDisplay)")
                    .font(.system(size: numberSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isOver ? CalorynTheme.terracotta : CalorynTheme.textPrimary)
                    .contentTransition(.numericText())

                Text("of \(target) kcal")
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
                    .multilineTextAlignment(.center)

                if !isOver, target > 0 {
                    Text("\(remaining) kcal left")
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.textSecondary.opacity(0.9))
                        .multilineTextAlignment(.center)
                } else if isOver {
                    Text("\(overAmount) kcal over")
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.terracotta.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: ringSize, height: ringSize)
        .padding(20)
        .glassCircle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue("\(consumedDisplay) of \(target) calories consumed")
        .onAppear {
            animatedRingProgress = displayedRingProgress
        }
        .onChange(of: displayedRingProgress) { _, newProgress in
            withAnimation(.smooth(duration: 0.45)) {
                animatedRingProgress = newProgress
            }
        }
    }

    private var accessibilityDescription: String {
        if isOver {
            "Calorie ring, \(consumedDisplay) calories logged, \(overAmount) calories over a \(target) calorie goal"
        } else {
            "Calorie ring, \(consumedDisplay) of \(target) calories logged, \(remaining) calories remaining"
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        CalorieRingView(consumed: 1200, target: 2000, ringSize: 200)
        CalorieRingView(consumed: 2200, target: 2000, ringSize: 200)
        CalorieRingView(consumed: 0, target: 2000, ringSize: 200)
    }
}
