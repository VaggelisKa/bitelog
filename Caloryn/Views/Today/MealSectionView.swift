import SwiftUI

struct MealSectionView: View {
    let mealType: MealType
    let entries: [FoodLogEntry]
    var snackIndex: Int
    var onAdd: () -> Void
    var onDelete: (FoodLogEntry) -> Void

    @State private var entryToDelete: FoodLogEntry?

    init(mealType: MealType, entries: [FoodLogEntry], snackIndex: Int = 0, onAdd: @escaping () -> Void, onDelete: @escaping (FoodLogEntry) -> Void) {
        self.mealType = mealType
        self.entries = entries
        self.snackIndex = snackIndex
        self.onAdd = onAdd
        self.onDelete = onDelete
    }

    private var sectionTitle: String {
        mealType == .snack ? mealType.displayName(snackIndex: snackIndex) : mealType.displayName
    }

    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.proteinG }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onAdd) {
                HStack {
                    Image(systemName: mealType.iconName)
                        .foregroundStyle(CalorynTheme.sage)
                        .font(.title2)

                    Text(sectionTitle)
                        .font(CalorynTheme.itemTitle)
                        .foregroundStyle(CalorynTheme.textPrimary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if !totalCalories.isZero {
                            Text(totalCalories.kcalFormatted)
                                .font(CalorynTheme.numericCaption)
                                .foregroundStyle(CalorynTheme.textSecondary)
                        }

                        if !entries.isEmpty, !totalProtein.isZero {
                            Text("\(totalProtein.macroFormatted) protein")
                                .font(CalorynTheme.numericCaption)
                                .foregroundStyle(CalorynTheme.proteinColor)
                        }
                    }

                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(CalorynTheme.sage)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add food to \(sectionTitle)")
            .accessibilityHint("Double tap to add food")

            if entries.isEmpty {
                Button(action: onAdd) {
                    VStack(spacing: 4) {
                        Text("No food logged yet")
                            .font(CalorynTheme.caption)
                            .foregroundStyle(CalorynTheme.textSecondary)
                        Text("Tap to add")
                            .font(.caption2)
                            .foregroundStyle(CalorynTheme.sage.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add food to \(sectionTitle)")
            } else {
                ForEach(entries) { entry in
                    MealEntryRow(entry: entry) {
                        entryToDelete = entry
                    }
                    if entry.id != entries.last?.id {
                        Divider()
                            .foregroundStyle(CalorynTheme.stone.opacity(0.3))
                    }
                }
            }
        }
        .glassCard()
        .confirmationDialog(
            "Delete Entry",
            isPresented: Binding(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    onDelete(entry)
                    entryToDelete = nil
                }
            }
        } message: {
            if let entry = entryToDelete {
                Text("Remove \(entry.foodName) from \(sectionTitle)?")
            }
        }
    }
}

private struct MealEntryRow: View {
    let entry: FoodLogEntry
    var onDelete: () -> Void

    @AppStorage("showNutriscore") private var showNutriscore = true

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.foodName)
                        .font(CalorynTheme.bodyText)
                        .foregroundStyle(CalorynTheme.textPrimary)
                        .lineLimit(1)

                    if showNutriscore, let grade = entry.foodItem?.nutriscoreGrade {
                        NutriscoreBadge(grade: grade)
                    }
                }

                if !entry.proteinG.isZero {
                    Text("\(Int(entry.portionGrams))g · \(entry.proteinG.macroFormatted) protein")
                        .font(CalorynTheme.caption)
                        .foregroundStyle(CalorynTheme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Text(entry.calories.kcalFormatted)
                    .font(CalorynTheme.numericCaption)
                    .foregroundStyle(CalorynTheme.textPrimary)

                Button(action: onDelete) {
                    Image(systemName: "minus.circle")
                        .font(.body)
                        .foregroundStyle(CalorynTheme.terracotta.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(entry.foodName)")
            }
        }
        .padding(.vertical, 4)
    }
}
