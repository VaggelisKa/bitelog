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

    private var isOver: Bool {
        consumed > Double(target)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    BiteLogTheme.sage.opacity(0.15),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedRingProgress)
                .stroke(
                    isOver ? BiteLogTheme.terracotta : BiteLogTheme.sage,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(animatedRingProgress < 0.01 ? 0 : 1)

            VStack(spacing: 2) {
                Text("\(remaining)")
                    .font(.system(size: numberSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isOver ? BiteLogTheme.terracotta : BiteLogTheme.textPrimary)
                    .contentTransition(.numericText())

                Text(isOver ? "over" : "remaining")
                    .font(BiteLogTheme.caption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .padding(20)
        .glassCircle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue("\(Int(consumed)) of \(target) calories consumed")
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
            "Calorie ring, over target by \(Int(consumed) - target) calories"
        } else {
            "Calorie ring, \(remaining) calories remaining"
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        CalorieRingView(consumed: 1200, target: 2000, ringSize: 180)
        CalorieRingView(consumed: 2200, target: 2000, ringSize: 180)
    }
}
