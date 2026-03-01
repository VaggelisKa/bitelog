import SwiftUI

struct WelcomeStepView: View {
    var onContinue: () -> Void

    @ScaledMetric private var iconSize: CGFloat = 80

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "flame.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(BiteLogTheme.sage)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    Text("BiteLog")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(BiteLogTheme.textPrimary)

                    Text("Track your calories.\nSimple, private, fast.")
                        .font(BiteLogTheme.bodyText)
                        .foregroundStyle(BiteLogTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .tint(BiteLogTheme.sage)

                Text("No account needed. Your data stays on-device.")
                    .font(BiteLogTheme.caption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, BiteLogTheme.pagePadding)
            .padding(.bottom, 40)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        WelcomeStepView { }
    }
}
