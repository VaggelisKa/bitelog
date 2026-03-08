import SwiftUI

struct NutriscoreBadge: View {
    let grade: String

    var body: some View {
        if let color = CalorynTheme.nutriscoreColor(for: grade) {
            Text(grade.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(color, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .accessibilityLabel("Nutri-Score \(grade.uppercased())")
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        NutriscoreBadge(grade: "a")
        NutriscoreBadge(grade: "b")
        NutriscoreBadge(grade: "c")
        NutriscoreBadge(grade: "d")
        NutriscoreBadge(grade: "e")
    }
    .padding()
}
