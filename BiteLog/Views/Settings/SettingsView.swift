import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var allEntries: [FoodLogEntry]
    @AppStorage("themePreference") private var themePreferenceRaw = ThemePreference.system.rawValue

    @State private var showExportSheet = false
    @State private var exportURL: URL?

    private var profile: UserProfile? { profiles.first }
    private var themePreference: ThemePreference {
        get { ThemePreference(rawValue: themePreferenceRaw) ?? .system }
        set { themePreferenceRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                appearanceSection

                if let profile {
                    goalSection(profile)
                    profileSection(profile)
                }

                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { themePreference },
                set: { themePreference = $0 }
            )) {
                ForEach(ThemePreference.allCases, id: \.self) { preference in
                    Text(preference.displayName).tag(preference)
                }
            }
            .tint(BiteLogTheme.sage)
        } header: {
            Text("Appearance")
        }
    }

    private func goalSection(_ profile: UserProfile) -> some View {
        Section {
            HStack {
                Text("Daily Target")
                Spacer()
                Text(profile.dailyCalorieTarget.kcalFormatted)
                    .font(BiteLogTheme.numericBody)
                    .foregroundStyle(BiteLogTheme.sage)
            }

            NavigationLink("Edit Goal") {
                GoalEditView(profile: profile)
            }
        } header: {
            Text("Goal")
        }
    }

    private func profileSection(_ profile: UserProfile) -> some View {
        Section {
            LabeledContent("Age", value: "\(profile.age)")
            LabeledContent("Sex", value: profile.sex.displayName)
            LabeledContent("Height", value: "\(Int(profile.heightCm)) cm")
            LabeledContent("Weight", value: String(format: "%.1f kg", profile.weightKg))
            LabeledContent("Activity", value: profile.activityLevel.displayName)

            NavigationLink("Edit Profile") {
                ProfileEditView(profile: profile)
            }
        } header: {
            Text("Profile")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                exportURL = CSVExporter.exportURL(from: allEntries)
                if exportURL != nil {
                    showExportSheet = true
                }
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(allEntries.isEmpty)
        } header: {
            Text("Data")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0.0")

            Link(destination: URL(string: "https://bitelog.app/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundStyle(BiteLogTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .foregroundStyle(BiteLogTheme.textSecondary)
                }
            }

            HStack {
                Text("Food data by")
                Spacer()
                Link("Open Food Facts", destination: URL(string: "https://openfoodfacts.org")!)
                    .font(BiteLogTheme.caption)
            }
        } header: {
            Text("About")
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Goal Edit

struct GoalEditView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var targetText: String = ""
    @State private var proteinRatio: Double = 0.30
    @State private var carbRatio: Double = 0.40
    @State private var fatRatio: Double = 0.30

    var body: some View {
        Form {
            Section("Daily Calorie Target") {
                Toggle("Manual Override", isOn: $profile.manualOverride)
                    .tint(BiteLogTheme.sage)

                if profile.manualOverride {
                    HStack {
                        TextField("Target", text: $targetText)
                            .keyboardType(.numberPad)
                            .onChange(of: targetText) {
                                if let val = Int(targetText), val >= 1000 {
                                    profile.dailyCalorieTarget = val
                                }
                            }
                        Text("kcal")
                            .foregroundStyle(BiteLogTheme.textSecondary)
                    }
                } else {
                    LabeledContent("Calculated TDEE", value: "\(Int(profile.tdee)) kcal")
                    LabeledContent("Target (-500)", value: "\(NutritionCalculator.defaultTarget(tdee: profile.tdee)) kcal")
                }
            }

            Section("Macro Ratios") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protein: \(Int(proteinRatio * 100))%")
                    Slider(value: $proteinRatio, in: 0.10...0.50, step: 0.05)
                        .tint(BiteLogTheme.proteinColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carbs: \(Int(carbRatio * 100))%")
                    Slider(value: $carbRatio, in: 0.10...0.60, step: 0.05)
                        .tint(BiteLogTheme.carbColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fat: \(Int(fatRatio * 100))%")
                    Slider(value: $fatRatio, in: 0.10...0.50, step: 0.05)
                        .tint(BiteLogTheme.fatColor)
                }

                let total = proteinRatio + carbRatio + fatRatio
                if abs(total - 1.0) > 0.01 {
                    Text("Ratios should total 100% (currently \(Int(total * 100))%)")
                        .font(BiteLogTheme.caption)
                        .foregroundStyle(BiteLogTheme.terracotta)
                }
            }

            Section {
                Button("Save Changes") {
                    profile.recalculate(proteinRatio: proteinRatio, carbRatio: carbRatio, fatRatio: fatRatio)
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(BiteLogTheme.sage)
                .font(.headline)
            }
        }
        .navigationTitle("Edit Goal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            targetText = "\(profile.dailyCalorieTarget)"
        }
    }
}

// MARK: - Profile Edit

struct ProfileEditView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Personal Info") {
                Stepper("Age: \(profile.age)", value: $profile.age, in: 16...100)

                Picker("Sex", selection: $profile.sex) {
                    ForEach(Sex.allCases) { s in
                        Text(s.displayName).tag(s)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Height: \(Int(profile.heightCm)) cm")
                    Slider(value: $profile.heightCm, in: 120...220, step: 1)
                        .tint(BiteLogTheme.sage)
                }

                VStack(alignment: .leading) {
                    Text("Weight: \(String(format: "%.1f", profile.weightKg)) kg")
                    Slider(value: $profile.weightKg, in: 40...200, step: 0.5)
                        .tint(BiteLogTheme.sage)
                }
            }

            Section("Activity Level") {
                Picker("Activity", selection: $profile.activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }

            Section {
                Button("Save & Recalculate") {
                    profile.recalculate()
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(BiteLogTheme.sage)
                .font(.headline)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
