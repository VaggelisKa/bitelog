import SwiftUI

struct PersonalInfoStepView: View {
    @Binding var age: Int
    @Binding var sex: Sex
    @Binding var heightCm: Double
    @Binding var weightKg: Double
    var onContinue: () -> Void

    @ScaledMetric private var spacing: CGFloat = 24

    var body: some View {
        ScrollView {
            VStack(spacing: spacing) {
                VStack(spacing: 8) {
                    Text("About You")
                        .font(BiteLogTheme.sectionTitle)
                        .foregroundStyle(BiteLogTheme.textPrimary)
                    Text("We'll use this to calculate your daily target.")
                        .font(BiteLogTheme.bodyText)
                        .foregroundStyle(BiteLogTheme.textSecondary)
                }
                .padding(.top, 8)

                VStack(spacing: BiteLogTheme.cardSpacing) {
                    fieldCard("Sex") {
                        Picker("Sex", selection: $sex) {
                            ForEach(Sex.allCases) { s in
                                Text(s.displayName).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    fieldCard("Age") {
                        HStack {
                            Text("\(age) years")
                                .font(BiteLogTheme.numericBody)
                                .foregroundStyle(BiteLogTheme.textPrimary)
                            Spacer()
                            Stepper("", value: $age, in: 16...100)
                                .labelsHidden()
                        }
                    }

                    fieldCard("Height") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(Int(heightCm)) cm")
                                .font(BiteLogTheme.numericBody)
                                .foregroundStyle(BiteLogTheme.textPrimary)
                            Slider(value: $heightCm, in: 120...220, step: 1)
                                .tint(BiteLogTheme.sage)
                        }
                    }

                    fieldCard("Weight") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(format: "%.1f kg", weightKg))
                                .font(BiteLogTheme.numericBody)
                                .foregroundStyle(BiteLogTheme.textPrimary)
                            Slider(value: $weightKg, in: 40...200, step: 0.5)
                                .tint(BiteLogTheme.sage)
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

    private func fieldCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(BiteLogTheme.caption)
                .foregroundStyle(BiteLogTheme.textSecondary)
                .textCase(.uppercase)
            content()
        }
        .glassCard(cornerRadius: BiteLogTheme.smallCornerRadius)
    }
}

#Preview {
    NavigationStack {
        PersonalInfoStepView(
            age: .constant(30),
            sex: .constant(.male),
            heightCm: .constant(175),
            weightKg: .constant(75)
        ) { }
    }
}
