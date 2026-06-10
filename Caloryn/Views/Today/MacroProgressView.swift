import SwiftUI

struct MacroProgressView: View {
    let entries: [FoodLogEntry]
    let proteinTarget: Double
    let carbTarget: Double
    let fatTarget: Double

    @AppStorage("todayTrackedNutrients") private var selectedNutrientIDs = TrackedNutrient.defaultSelectionRaw
    @State private var showingCustomizer = false
    @State private var customizationDetent = PresentationDetent.medium

    private var selectedMetrics: [TrackedNutrientMetric] {
        TrackedNutrient.selected(from: selectedNutrientIDs).map(metric(for:))
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()

                Button {
                    customizationDetent = selectedMetrics.count > TrackedNutrient.minimumSelectionCount ? .large : .medium
                    showingCustomizer = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(.subheadline, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(CalorynTheme.sage)
                .accessibilityLabel("Customize displayed nutrients")
            }
            .padding(.horizontal, 2)

            nutrientStrip
        }
        .sheet(isPresented: $showingCustomizer) {
            NutrientCustomizationView(
                selectedNutrientIDs: $selectedNutrientIDs,
                customizationDetent: $customizationDetent
            )
                .presentationDetents([.medium, .large], selection: $customizationDetent)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var nutrientStrip: some View {
        if selectedMetrics.count <= 3 {
            HStack(spacing: 16) {
                ForEach(selectedMetrics) { metric in
                    NutrientMetricTile(metric: metric)
                }
            }
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(selectedMetrics) { metric in
                        NutrientMetricTile(metric: metric)
                            .frame(width: 104)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
            .mask(TrailingScrollFadeMask())
        }
    }

    private func metric(for nutrient: TrackedNutrient) -> TrackedNutrientMetric {
        TrackedNutrientMetric(
            nutrient: nutrient,
            value: nutrient.value(in: entries),
            target: target(for: nutrient)
        )
    }

    private func target(for nutrient: TrackedNutrient) -> Double? {
        switch nutrient {
        case .protein:
            proteinTarget
        case .carbs:
            carbTarget
        case .fat:
            fatTarget
        case .fiber, .sugars, .addedSugars, .saturatedFat, .sodium, .cholesterol, .alcohol:
            nil
        }
    }
}

private struct TrailingScrollFadeMask: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.16),
                            .init(color: .black.opacity(0.56), location: 0.58),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 42)
        }
    }
}

private enum TrackedNutrient: String, CaseIterable, Identifiable {
    case protein
    case carbs
    case fat
    case fiber
    case sugars
    case addedSugars
    case saturatedFat
    case sodium
    case cholesterol
    case alcohol

    var id: String { rawValue }

    static let minimumSelectionCount = 3
    static let defaultSelection: [TrackedNutrient] = [.protein, .carbs, .fat]
    static let defaultSelectionRaw = rawSelection(from: defaultSelection)

    static func selected(from rawValue: String) -> [TrackedNutrient] {
        let nutrients = rawValue
            .split(separator: ",")
            .compactMap { TrackedNutrient(rawValue: String($0)) }
            .reduce(into: [TrackedNutrient]()) { selected, nutrient in
                guard !selected.contains(nutrient) else { return }
                selected.append(nutrient)
            }

        return normalizedSelection(from: nutrients)
    }

    static func rawSelection(from nutrients: [TrackedNutrient]) -> String {
        nutrients.map(\.rawValue).joined(separator: ",")
    }

    static func normalizedSelection(from nutrients: [TrackedNutrient]) -> [TrackedNutrient] {
        var selection = nutrients.reduce(into: [TrackedNutrient]()) { selected, nutrient in
            guard !selected.contains(nutrient) else { return }
            selected.append(nutrient)
        }

        if selection.isEmpty {
            selection = defaultSelection
        }

        for nutrient in defaultSelection where selection.count < minimumSelectionCount && !selection.contains(nutrient) {
            selection.append(nutrient)
        }

        for nutrient in allCases where selection.count < minimumSelectionCount && !selection.contains(nutrient) {
            selection.append(nutrient)
        }

        return selection
    }

    var displayName: String {
        switch self {
        case .protein:
            "Protein"
        case .carbs:
            "Carbs"
        case .fat:
            "Fat"
        case .fiber:
            "Fiber"
        case .sugars:
            "Sugars"
        case .addedSugars:
            "Added Sugars"
        case .saturatedFat:
            "Saturated Fat"
        case .sodium:
            "Sodium"
        case .cholesterol:
            "Cholesterol"
        case .alcohol:
            "Alcohol"
        }
    }

    var compactName: String {
        switch self {
        case .addedSugars:
            "Added Sugar"
        case .saturatedFat:
            "Sat Fat"
        default:
            displayName
        }
    }

    var systemImage: String {
        switch self {
        case .protein:
            "bolt.fill"
        case .carbs:
            "chart.bar.xaxis"
        case .fat:
            "drop.fill"
        case .fiber:
            "leaf.fill"
        case .sugars:
            "cube.fill"
        case .addedSugars:
            "plus.circle.fill"
        case .saturatedFat:
            "drop.fill"
        case .sodium:
            "circle.grid.cross"
        case .cholesterol:
            "heart.fill"
        case .alcohol:
            "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .protein:
            CalorynTheme.proteinColor
        case .carbs, .sugars:
            CalorynTheme.carbColor
        case .fat, .addedSugars, .saturatedFat, .cholesterol:
            CalorynTheme.fatColor
        case .fiber:
            CalorynTheme.fiberColor
        case .sodium:
            CalorynTheme.stone
        case .alcohol:
            CalorynTheme.textSecondary
        }
    }

    var unit: TrackedNutrientUnit {
        switch self {
        case .sodium, .cholesterol:
            .milligramsFromGrams
        case .protein, .carbs, .fat, .fiber, .sugars, .addedSugars, .saturatedFat, .alcohol:
            .grams
        }
    }

    func value(in entries: [FoodLogEntry]) -> Double {
        switch self {
        case .protein:
            total(entries, \.proteinG)
        case .carbs:
            total(entries, \.carbsG)
        case .fat:
            total(entries, \.fatG)
        case .fiber:
            total(entries, \.fiberG)
        case .sugars:
            optionalTotal(entries, \.sugarsG)
        case .addedSugars:
            optionalTotal(entries, \.addedSugarsG)
        case .saturatedFat:
            optionalTotal(entries, \.saturatedFatG)
        case .sodium:
            optionalTotal(entries, \.sodiumG)
        case .cholesterol:
            optionalTotal(entries, \.cholesterolG)
        case .alcohol:
            optionalTotal(entries, \.alcoholG)
        }
    }

    private func total(_ entries: [FoodLogEntry], _ keyPath: KeyPath<FoodLogEntry, Double>) -> Double {
        entries.reduce(0) { $0 + $1[keyPath: keyPath] }
    }

    private func optionalTotal(_ entries: [FoodLogEntry], _ keyPath: KeyPath<FoodLogEntry, Double?>) -> Double {
        entries.reduce(0) { $0 + ($1[keyPath: keyPath] ?? 0) }
    }
}

private enum TrackedNutrientUnit {
    case grams
    case milligramsFromGrams

    func formatted(_ value: Double) -> String {
        switch self {
        case .grams:
            value.macroFormatted
        case .milligramsFromGrams:
            "\(Int((value * 1000).rounded()))mg"
        }
    }
}

private struct TrackedNutrientMetric: Identifiable {
    let nutrient: TrackedNutrient
    let value: Double
    let target: Double?

    var id: String { nutrient.id }

    var formattedValue: String {
        return nutrient.unit.formatted(value)
    }

    var formattedTarget: String? {
        guard let target, target > 0 else { return nil }
        return nutrient.unit.formatted(target)
    }

    var progress: Double {
        guard let target, target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    var accessibilityLabel: String {
        let formattedCurrent = nutrient.unit.formatted(value)
        if let formattedTarget {
            return "\(nutrient.displayName): \(formattedCurrent) of \(formattedTarget)"
        }
        return "\(nutrient.displayName): \(formattedCurrent) today"
    }
}

private struct NutrientMetricTile: View {
    let metric: TrackedNutrientMetric

    var body: some View {
        VStack(spacing: 6) {
            Text(metric.nutrient.compactName)
                .font(CalorynTheme.caption)
                .foregroundStyle(CalorynTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let formattedTarget = metric.formattedTarget {
                progressBar

                Text("\(metric.formattedValue) / \(formattedTarget)")
                    .font(CalorynTheme.numericCaption)
                    .foregroundStyle(CalorynTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else {
                Text(metric.formattedValue)
                    .font(CalorynTheme.numericCaption)
                    .foregroundStyle(metric.nutrient.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("today")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(CalorynTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metric.accessibilityLabel)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(metric.nutrient.color.opacity(0.15))

                Capsule()
                    .fill(metric.nutrient.color)
                    .frame(width: geo.size.width * metric.progress)
                    .animation(.smooth(duration: 0.5), value: metric.progress)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

private struct NutrientCustomizationView: View {
    @Binding var selectedNutrientIDs: String
    @Binding var customizationDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    @State private var editMode = EditMode.active

    private var selectedNutrients: [TrackedNutrient] {
        get {
            TrackedNutrient.selected(from: selectedNutrientIDs)
        }
        nonmutating set {
            let nextSelection = TrackedNutrient.normalizedSelection(from: newValue)
            selectedNutrientIDs = TrackedNutrient.rawSelection(from: nextSelection)
        }
    }

    private var availableNutrients: [TrackedNutrient] {
        TrackedNutrient.allCases.filter { !selectedNutrients.contains($0) }
    }

    private var visibleSectionID: String {
        TrackedNutrient.rawSelection(from: selectedNutrients)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Visible") {
                    ForEach(selectedNutrients) { nutrient in
                        SelectedNutrientRow(
                            nutrient: nutrient,
                            canRemove: selectedNutrients.count > TrackedNutrient.minimumSelectionCount,
                            onRemove: { remove(nutrient) }
                        )
                    }
                    .onMove(perform: moveSelectedNutrients)
                }
                .id(visibleSectionID)

                if !availableNutrients.isEmpty {
                    Section("Available") {
                        ForEach(availableNutrients) { nutrient in
                            Button {
                                add(nutrient)
                            } label: {
                                HStack {
                                    Label(nutrient.displayName, systemImage: nutrient.systemImage)
                                        .foregroundStyle(CalorynTheme.textPrimary)

                                    Spacer()

                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(CalorynTheme.sage)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Add \(nutrient.displayName)")
                        }
                    }
                }

                Section {
                    Button("Reset to Default") {
                        selectedNutrients = TrackedNutrient.defaultSelection
                    }
                    .foregroundStyle(CalorynTheme.sage)
                }
            }
            .navigationTitle("Displayed Nutrients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .environment(\.editMode, $editMode)
            .onAppear(perform: refreshEditState)
            .onChange(of: selectedNutrientIDs) { _, _ in
                refreshEditState()
            }
        }
    }

    private func add(_ nutrient: TrackedNutrient) {
        guard !selectedNutrients.contains(nutrient) else { return }
        var nutrients = selectedNutrients
        nutrients.append(nutrient)
        selectedNutrients = nutrients
        refreshEditState()
    }

    private func remove(_ nutrient: TrackedNutrient) {
        guard selectedNutrients.count > TrackedNutrient.minimumSelectionCount else { return }
        var nutrients = selectedNutrients
        nutrients.removeAll { $0 == nutrient }
        selectedNutrients = nutrients
    }

    private func moveSelectedNutrients(from source: IndexSet, to destination: Int) {
        var nutrients = selectedNutrients
        nutrients.move(fromOffsets: source, toOffset: destination)
        selectedNutrients = nutrients
    }

    private func refreshEditState() {
        editMode = .active

        if selectedNutrients.count > TrackedNutrient.minimumSelectionCount {
            customizationDetent = .large
        }
    }
}

private struct SelectedNutrientRow: View {
    let nutrient: TrackedNutrient
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label(nutrient.displayName, systemImage: nutrient.systemImage)
                .foregroundStyle(CalorynTheme.textPrimary)
                .accessibilityHint("Drag to reorder")

            Spacer()

            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("Remove \(nutrient.displayName)")
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(CalorynTheme.sage)
    }
}

#Preview {
    let oatmeal = FoodItem(
        name: "Oatmeal",
        caloriesPer100g: 389,
        proteinPer100g: 16.9,
        carbsPer100g: 66.3,
        fatPer100g: 6.9,
        fiberPer100g: 10.6,
        sugarsPer100g: 0.9,
        saturatedFatPer100g: 1.2,
        sodiumPer100g: 0.002
    )
    let apple = FoodItem(
        name: "Apple",
        caloriesPer100g: 52,
        proteinPer100g: 0.3,
        carbsPer100g: 14,
        fatPer100g: 0.2,
        fiberPer100g: 2.4,
        sugarsPer100g: 10.4
    )

    MacroProgressView(
        entries: [
            FoodLogEntry(date: .now, mealType: .breakfast, foodItem: oatmeal, portionGrams: 80),
            FoodLogEntry(date: .now, mealType: .snack, foodItem: apple, portionGrams: 120)
        ],
        proteinTarget: 120,
        carbTarget: 200,
        fatTarget: 65
    )
    .padding()
}
