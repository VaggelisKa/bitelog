import SwiftData
import SwiftUI

struct RecipesView: View {
    @Query(sort: \FoodItem.name) private var foodItems: [FoodItem]

    @State private var showingRecipeForm = false
    @State private var editingRecipe: FoodItem?

    private var recipes: [FoodItem] {
        foodItems.filter(\.isRecipe)
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    emptyState
                } else {
                    recipeList
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingRecipeForm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CalorynTheme.sage)
                    }
                    .accessibilityLabel("Create Recipe")
                }
            }
            .sheet(isPresented: $showingRecipeForm) {
                RecipeFormView()
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingRecipe) { recipe in
                RecipeFormView(existingRecipe: recipe)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Recipes", systemImage: "list.bullet.rectangle")
        } description: {
            Text("Create your first recipe to build your library.")
        } actions: {
            Button {
                showingRecipeForm = true
            } label: {
                Label("Create Recipe", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .tint(CalorynTheme.sage)
        }
    }

    private var recipeList: some View {
        List {
            ForEach(recipes) { recipe in
                Button {
                    editingRecipe = recipe
                } label: {
                    RecipeLibraryRow(recipe: recipe)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }
}

private struct RecipeLibraryRow: View {
    let recipe: FoodItem

    private var totalGrams: Double {
        recipe.defaultServingG ?? 0
    }

    private var ingredientCount: Int {
        recipe.recipeIngredients?.count ?? 0
    }

    private var calories: Double {
        recipe.calories(forGrams: totalGrams)
    }

    private var protein: Double {
        recipe.protein(forGrams: totalGrams)
    }

    private var carbs: Double {
        recipe.carbs(forGrams: totalGrams)
    }

    private var fat: Double {
        recipe.fat(forGrams: totalGrams)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "list.bullet.rectangle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(CalorynTheme.sage)
                .frame(width: 34, height: 34)
                .background(CalorynTheme.sage.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(CalorynTheme.itemTitle)
                    .foregroundStyle(CalorynTheme.textPrimary)
                    .lineLimit(1)

                Text(recipeDetail)
                    .font(CalorynTheme.caption)
                    .foregroundStyle(CalorynTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(calories.rounded()))")
                    .font(CalorynTheme.numericBody)
                    .foregroundStyle(CalorynTheme.textPrimary)

                Text("kcal total")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(CalorynTheme.textSecondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var recipeDetail: String {
        let ingredientLabel = ingredientCount == 1 ? "1 ingredient" : "\(ingredientCount) ingredients"
        let macroLabel = "\(protein.macroFormatted) P · \(carbs.macroFormatted) C · \(fat.macroFormatted) F"

        guard totalGrams > 0 else {
            return "\(ingredientLabel) · \(macroLabel)"
        }

        return "\(ingredientLabel) · \(Int(totalGrams.rounded()))g · \(macroLabel)"
    }
}

#Preview {
    RecipesView()
        .modelContainer(for: [UserProfile.self, FoodItem.self, FoodLogEntry.self, RecipeIngredient.self], inMemory: true)
}
