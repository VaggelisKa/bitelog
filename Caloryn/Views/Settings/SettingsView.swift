import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Query private var allEntries: [FoodLogEntry]
    @AppStorage("themePreference") private var themePreferenceRaw = ThemePreference.system.rawValue
    @AppStorage("showNutriscore") private var showNutriscore = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true

    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showRestartAlert = false

    private var profile: UserProfile? { profiles.first }

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
            .alert("Restart Required", isPresented: $showRestartAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("iCloud sync changes will take effect the next time you open the app.")
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $themePreferenceRaw) {
                ForEach(ThemePreference.allCases, id: \.self) { preference in
                    Label(preference.displayName, systemImage: preference.icon)
                        .tag(preference.rawValue)
                }
            }
            .tint(CalorynTheme.sage)

            Toggle(isOn: $showNutriscore) {
                Label("Show Nutri-Score", systemImage: "leaf")
            }
            .tint(CalorynTheme.sage)
        } header: {
            Text("Appearance")
        } footer: {
            Text("Display nutrition quality scores from Open Food Facts on foods and in your daily summary.")
        }
    }

    private func goalSection(_ profile: UserProfile) -> some View {
        Section {
            HStack {
                Text("Daily Target")
                Spacer()
                Text(profile.dailyCalorieTarget.kcalFormatted)
                    .font(CalorynTheme.numericBody)
                    .foregroundStyle(CalorynTheme.sage)
            }

            if !profile.manualOverride {
                HStack {
                    Text("Adjustment")
                    Spacer()
                    Text(adjustmentLabel(for: profile.calorieDeficit))
                        .font(CalorynTheme.numericBody)
                        .foregroundStyle(CalorynTheme.textSecondary)
                }
            }

            NavigationLink("Edit Goal") {
                GoalEditView(profile: profile)
            }
        } header: {
            Text("Goal")
        }
    }

    private func adjustmentLabel(for deficit: Double) -> String {
        if deficit > 0 {
            return "-\(Int(deficit)) kcal"
        } else if deficit < 0 {
            return "+\(Int(abs(deficit))) kcal"
        }
        return "Maintenance"
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
            Toggle(isOn: $iCloudSyncEnabled) {
                Label("iCloud Sync", systemImage: "icloud")
            }
            .tint(CalorynTheme.sage)
            .onChange(of: iCloudSyncEnabled) {
                showRestartAlert = true
            }

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
        } footer: {
            if iCloudSyncEnabled {
                Text("Your food log syncs automatically across your devices via iCloud.")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")

            Link(destination: URL(string: "https://caloryn.app/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundStyle(CalorynTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .foregroundStyle(CalorynTheme.textSecondary)
                }
            }

            HStack {
                Text("Food data by")
                Spacer()
                Link("Open Food Facts", destination: URL(string: "https://openfoodfacts.org")!)
                    .font(CalorynTheme.caption)
            }
        } header: {
            Text("About")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, FoodItem.self, FoodLogEntry.self, configurations: config)
    let context = ModelContext(container)
    let profile = UserProfile(age: 30, sex: .male, heightCm: 175, weightKg: 70, activityLevel: .moderatelyActive, dailyCalorieTarget: 2000)
    context.insert(profile)
    try? context.save()
    return SettingsView()
        .modelContainer(container)
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
    @State private var calorieDeficit: Double = 500
    @State private var proteinRatio: Double = 0.30
    @State private var carbRatio: Double = 0.40
    @State private var fatRatio: Double = 0.30

    private var macroTotal: Double { proteinRatio + carbRatio + fatRatio }
    private var isMacroValid: Bool { abs(macroTotal - 1.0) <= 0.01 }

    private var calculatedTarget: Int {
        NutritionCalculator.defaultTarget(tdee: profile.tdee, deficit: calorieDeficit)
    }

    private var deficitLabel: String {
        if calorieDeficit > 0 {
            return "-\(Int(calorieDeficit)) kcal/day (lose weight)"
        } else if calorieDeficit < 0 {
            return "+\(Int(abs(calorieDeficit))) kcal/day (gain weight)"
        }
        return "Maintenance (no change)"
    }

    var body: some View {
        Form {
            Section("Daily Calorie Target") {
                Toggle("Manual Override", isOn: $profile.manualOverride)
                    .tint(CalorynTheme.sage)
                    .onChange(of: profile.manualOverride) { _, isManual in
                        if isManual {
                            targetText = "\(calculatedTarget)"
                        }
                    }

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
                            .foregroundStyle(CalorynTheme.textSecondary)
                    }
                } else {
                    LabeledContent("Calculated TDEE", value: "\(Int(profile.tdee)) kcal")
                    LabeledContent("Target", value: "\(calculatedTarget) kcal")
                }
            }

            if !profile.manualOverride {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Surplus")
                                .font(.caption2)
                                .foregroundStyle(CalorynTheme.textSecondary)
                            Slider(value: $calorieDeficit, in: -500...1000, step: 50)
                                .tint(CalorynTheme.sage)
                            Text("Deficit")
                                .font(.caption2)
                                .foregroundStyle(CalorynTheme.textSecondary)
                        }

                        Text(deficitLabel)
                            .font(CalorynTheme.caption)
                            .foregroundStyle(CalorynTheme.terracotta)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } header: {
                    Text("Calorie Adjustment")
                } footer: {
                    Text("Positive values create a deficit for weight loss, negative values create a surplus for weight gain.")
                }
            }

            Section("Macro Ratios") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protein: \(Int(proteinRatio * 100))%")
                    Slider(value: $proteinRatio, in: 0.10...0.50, step: 0.05)
                        .tint(CalorynTheme.proteinColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carbs: \(Int(carbRatio * 100))%")
                    Slider(value: $carbRatio, in: 0.10...0.60, step: 0.05)
                        .tint(CalorynTheme.carbColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fat: \(Int(fatRatio * 100))%")
                    Slider(value: $fatRatio, in: 0.10...0.50, step: 0.05)
                        .tint(CalorynTheme.fatColor)
                }

                let total = proteinRatio + carbRatio + fatRatio
                if abs(total - 1.0) > 0.01 {
                    Text("Ratios should total 100% (currently \(Int(total * 100))%)")
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.terracotta)
                }
            }
        }
        .navigationTitle("Edit Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    profile.calorieDeficit = calorieDeficit
                    profile.recalculate(proteinRatio: proteinRatio, carbRatio: carbRatio, fatRatio: fatRatio)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(!isMacroValid)
            }
        }
        .onAppear {
            targetText = "\(profile.dailyCalorieTarget)"
            calorieDeficit = profile.calorieDeficit
            let cal = Double(profile.dailyCalorieTarget)
            if cal > 0 {
                proteinRatio = (profile.proteinTargetG * 4.0) / cal
                carbRatio = (profile.carbTargetG * 4.0) / cal
                fatRatio = (profile.fatTargetG * 9.0) / cal
            }
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
                        .tint(CalorynTheme.sage)
                }

                VStack(alignment: .leading) {
                    Text("Weight: \(String(format: "%.1f", profile.weightKg)) kg")
                    Slider(value: $profile.weightKg, in: 40...200, step: 0.5)
                        .tint(CalorynTheme.sage)
                }
            }

            Section("Activity Level") {
                Picker("Activity", selection: $profile.activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    profile.recalculate()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}
