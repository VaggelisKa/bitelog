import SwiftUI

struct ActivityLevelStepView: View {
    @Binding var activityLevel: ActivityLevel
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Activity Level")
                        .font(BiteLogTheme.sectionTitle)
                        .foregroundStyle(BiteLogTheme.textPrimary)
                    Text("How active are you on a typical week?")
                        .font(BiteLogTheme.bodyText)
                        .foregroundStyle(BiteLogTheme.textSecondary)
                }
                .padding(.top, 8)

                GlassEffectContainer(spacing: BiteLogTheme.cardSpacing) {
                    VStack(spacing: BiteLogTheme.cardSpacing) {
                        ForEach(ActivityLevel.allCases) { level in
                            ActivityLevelCard(
                                level: level,
                                isSelected: activityLevel == level
                            ) {
                                withAnimation(.smooth(duration: 0.25)) {
                                    activityLevel = level
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, BiteLogTheme.pagePadding)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .tint(BiteLogTheme.sage)
            .padding(.horizontal, BiteLogTheme.pagePadding)
            .padding(.bottom, 16)
        }
    }
}

private struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    var onTap: () -> Void

    private var contentForeground: Color {
        isSelected ? BiteLogTheme.warmWhite : BiteLogTheme.textPrimary
    }

    private var secondaryForeground: Color {
        isSelected ? BiteLogTheme.warmWhite.opacity(0.9) : BiteLogTheme.textSecondary
    }

    private var accentForeground: Color {
        isSelected ? BiteLogTheme.warmWhite : BiteLogTheme.sage
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: level.iconName)
                    .font(.title2)
                    .foregroundStyle(accentForeground)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(level.displayName)
                        .font(BiteLogTheme.itemTitle)
                        .foregroundStyle(contentForeground)
                    Text(level.description)
                        .font(BiteLogTheme.caption)
                        .foregroundStyle(secondaryForeground)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(accentForeground)
                    .font(.title3)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(BiteLogTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                isSelected ? .regular.tint(BiteLogTheme.sage).interactive() : .regular.interactive(),
                in: .rect(cornerRadius: BiteLogTheme.smallCornerRadius)
            )
            .animation(.smooth(duration: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ActivityLevelStepView(activityLevel: .constant(.moderatelyActive)) { }
    }
}
