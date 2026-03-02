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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: mealType.iconName)
                    .foregroundStyle(BiteLogTheme.sage)
                    .font(.title3)

                Text(sectionTitle)
                    .font(BiteLogTheme.itemTitle)
                    .foregroundStyle(BiteLogTheme.textPrimary)

                Spacer()

                Text(totalCalories.kcalFormatted)
                    .font(BiteLogTheme.numericCaption)
                    .foregroundStyle(BiteLogTheme.textSecondary)

                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(BiteLogTheme.sage)
                }
                .accessibilityLabel("Add food to \(sectionTitle)")
            }

            if entries.isEmpty {
                Text("No food logged yet")
                    .font(BiteLogTheme.caption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries) { entry in
                    MealEntryRow(entry: entry) {
                        entryToDelete = entry
                    }
                    if entry.id != entries.last?.id {
                        Divider()
                            .foregroundStyle(BiteLogTheme.stone.opacity(0.3))
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(BiteLogTheme.bodyText)
                    .foregroundStyle(BiteLogTheme.textPrimary)
                    .lineLimit(1)

                Text("\(Int(entry.portionGrams))g")
                    .font(BiteLogTheme.caption)
                    .foregroundStyle(BiteLogTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Text(entry.calories.kcalFormatted)
                    .font(BiteLogTheme.numericCaption)
                    .foregroundStyle(BiteLogTheme.textPrimary)

                Button(action: onDelete) {
                    Image(systemName: "minus.circle")
                        .font(.body)
                        .foregroundStyle(BiteLogTheme.terracotta.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(entry.foodName)")
            }
        }
        .padding(.vertical, 4)
    }
}
