import SwiftUI

struct ActivityLevelStepView: View {
    @Binding var activityLevel: ActivityLevel
    var onContinue: () -> Void

    @Namespace private var selectionAnimation

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
                                isSelected: activityLevel == level,
                                namespace: selectionAnimation
                            ) {
                                withAnimation(.smooth(duration: 0.3)) {
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
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

private struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    var namespace: Namespace.ID
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: level.iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? BiteLogTheme.sage : BiteLogTheme.textSecondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(level.displayName)
                        .font(BiteLogTheme.itemTitle)
                        .foregroundStyle(BiteLogTheme.textPrimary)
                    Text(level.description)
                        .font(BiteLogTheme.caption)
                        .foregroundStyle(BiteLogTheme.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BiteLogTheme.sage)
                        .font(.title3)
                }
            }
            .padding(BiteLogTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                isSelected ? .regular.tint(BiteLogTheme.sage).interactive() : .regular.interactive(),
                in: .rect(cornerRadius: BiteLogTheme.smallCornerRadius)
            )
            .glassEffectID(
                isSelected ? "selected" : "level-\(level.id)",
                in: namespace
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ActivityLevelStepView(activityLevel: .constant(.moderatelyActive)) { }
    }
}
