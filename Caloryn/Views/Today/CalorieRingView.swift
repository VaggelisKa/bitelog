import SwiftUI
import UIKit

struct CalorieRingView: View {
    let consumed: Double
    let baseTarget: Int
    let adjustedTarget: Int
    let activityCredit: Int
    let isActivityEnabled: Bool
    let isActivityLoading: Bool
    let ringSize: CGFloat
    var onDetailsRequested: (() -> Void)? = nil

    @ScaledMetric private var numberSize: CGFloat = 44
    @State private var animatedRingProgress: Double = 0
    @State private var isDetailsPressing = false

    private var progress: Double {
        guard adjustedTarget > 0 else { return 0 }
        return min(consumed / Double(adjustedTarget), 1.5)
    }

    private var displayedRingProgress: Double {
        min(progress, 1.0)
    }

    private var remaining: Int {
        max(0, adjustedTarget - Int(consumed))
    }

    private var overAmount: Int {
        max(0, Int(consumed) - adjustedTarget)
    }

    private var isOver: Bool {
        consumed > Double(adjustedTarget)
    }

    private var consumedDisplay: Int {
        Int(consumed.rounded(.towardZero))
    }

    private var hasActivityCredit: Bool {
        isActivityEnabled && activityCredit > 0 && adjustedTarget > baseTarget
    }

    private var baseProgressEnd: Double {
        guard adjustedTarget > 0 else { return 1 }
        return min(max(Double(baseTarget) / Double(adjustedTarget), 0), 1)
    }

    private var animatedBaseProgress: Double {
        hasActivityCredit ? min(animatedRingProgress, baseProgressEnd) : animatedRingProgress
    }

    private var animatedCreditProgress: Double {
        guard hasActivityCredit, animatedRingProgress > baseProgressEnd else { return baseProgressEnd }
        return min(animatedRingProgress, 1)
    }

    private var activityCreditColor: Color {
        CalorynTheme.carbColor
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    CalorynTheme.sage.opacity(0.15),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )

            Circle()
                .trim(from: baseProgressEnd, to: hasActivityCredit ? 1 : baseProgressEnd)
                .stroke(
                    activityCreditColor.opacity(0.42),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(hasActivityCredit ? 1 : 0)

            Circle()
                .trim(from: 0, to: animatedBaseProgress)
                .stroke(
                    isOver ? CalorynTheme.terracotta : CalorynTheme.sage,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(animatedRingProgress < 0.01 ? 0 : 1)

            Circle()
                .trim(from: baseProgressEnd, to: animatedCreditProgress)
                .stroke(
                    isOver ? CalorynTheme.terracotta : activityCreditColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(hasActivityCredit && animatedCreditProgress > baseProgressEnd ? 1 : 0)

            VStack(spacing: 2) {
                if isOver {
                    Text("\(overAmount)")
                        .font(.system(size: numberSize, weight: .bold, design: .rounded))
                        .foregroundStyle(CalorynTheme.terracotta)
                        .contentTransition(.numericText())

                    Text("over")
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.terracotta.opacity(0.85))
                } else {
                    Text("\(remaining)")
                        .font(.system(size: numberSize, weight: .bold, design: .rounded))
                        .foregroundStyle(CalorynTheme.textPrimary)
                        .contentTransition(.numericText())

                    Text("remaining")
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.textSecondary)
                }

                Text("\(consumedDisplay) eaten")
                    .font(CalorynTheme.caption)
                    .foregroundStyle(isOver ? CalorynTheme.terracotta.opacity(0.7) : CalorynTheme.textSecondary.opacity(0.75))
                    .padding(.top, 6)

                activityCreditCue
            }
        }
        .frame(width: ringSize, height: ringSize)
        .padding(20)
        .glassCircle()
        .contentShape(Circle())
        .scaleEffect(isDetailsPressing ? 0.94 : 1)
        .animation(.smooth(duration: 0.2), value: isDetailsPressing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(isOver
            ? "\(consumedDisplay) eaten, \(overAmount) calories over target of \(adjustedTarget)"
            : "\(consumedDisplay) eaten, \(remaining) remaining of \(adjustedTarget)"
        )
        .accessibilityHint(onDetailsRequested == nil ? "" : "Tap or long press to show nutrition details.")
        .accessibilityAddTraits(onDetailsRequested == nil ? [] : .isButton)
        .accessibilityAction(named: Text("Show nutrition details")) {
            requestDetails()
        }
        .onTapGesture(perform: requestDetails)
        .onLongPressGesture(
            minimumDuration: 0.45,
            maximumDistance: 24,
            pressing: setDetailsPressing,
            perform: requestDetails
        )
        .onAppear {
            animatedRingProgress = displayedRingProgress
        }
        .onChange(of: displayedRingProgress) { _, newProgress in
            withAnimation(.smooth(duration: 0.45)) {
                animatedRingProgress = newProgress
            }
        }
    }

    @ViewBuilder
    private var activityCreditCue: some View {
        if isActivityLoading {
            HStack(spacing: 5) {
                ProgressView()
                    .controlSize(.mini)

                Text("updating")
                    .lineLimit(1)
            }
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(CalorynTheme.textSecondary)
            .padding(.top, 2)
        } else if hasActivityCredit {
            Text("+\(activityCredit) activity")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(activityCreditColor)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.top, 2)
        }
    }

    private var accessibilityDescription: String {
        let activityDescription = hasActivityCredit ? ", includes \(activityCredit) calorie activity credit" : ""

        if isOver {
            return "Calorie ring, \(consumedDisplay) eaten, \(overAmount) calories over a \(adjustedTarget) calorie goal\(activityDescription)"
        } else {
            return "Calorie ring, \(remaining) remaining of \(adjustedTarget) calories, \(consumedDisplay) eaten\(activityDescription)"
        }
    }

    private func setDetailsPressing(_ pressing: Bool) {
        guard onDetailsRequested != nil else { return }
        guard isDetailsPressing != pressing else { return }
        if pressing {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred(intensity: 0.55)
        }
        isDetailsPressing = pressing
    }

    private func requestDetails() {
        guard let onDetailsRequested else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.75)
        isDetailsPressing = false
        onDetailsRequested()
    }
}

#Preview("Ring - No Activity") {
    CalorieRingView(
        consumed: 1200,
        baseTarget: 2000,
        adjustedTarget: 2000,
        activityCredit: 0,
        isActivityEnabled: false,
        isActivityLoading: false,
        ringSize: 220
    )
    .padding()
}

#Preview("Ring - Activity Credit") {
    CalorieRingView(
        consumed: 2070,
        baseTarget: 2000,
        adjustedTarget: 2350,
        activityCredit: 350,
        isActivityEnabled: true,
        isActivityLoading: false,
        ringSize: 220
    )
    .padding()
}

#Preview("Ring - Over Adjusted Target") {
    CalorieRingView(
        consumed: 2450,
        baseTarget: 2000,
        adjustedTarget: 2350,
        activityCredit: 350,
        isActivityEnabled: true,
        isActivityLoading: false,
        ringSize: 220
    )
    .padding()
}

#Preview("Ring - Loading Activity") {
    CalorieRingView(
        consumed: 1200,
        baseTarget: 2000,
        adjustedTarget: 2000,
        activityCredit: 0,
        isActivityEnabled: true,
        isActivityLoading: true,
        ringSize: 220
    )
    .padding()
}
