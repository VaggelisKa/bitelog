import Foundation

enum CSVExporter {
    static func generateCSV(from entries: [FoodLogEntry]) -> String {
        var csv = "Date,Meal,Food,Portion (g),Calories,Protein (g),Carbs (g),Fat (g)\n"

        let sorted = entries.sorted { $0.date < $1.date }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for entry in sorted {
            let date = formatter.string(from: entry.date)
            let meal = entry.mealType.displayName
            let food = entry.foodName.replacingOccurrences(of: ",", with: ";")
            let portion = String(format: "%.0f", entry.portionGrams)
            let cal = String(format: "%.0f", entry.calories)
            let protein = String(format: "%.1f", entry.proteinG)
            let carbs = String(format: "%.1f", entry.carbsG)
            let fat = String(format: "%.1f", entry.fatG)

            csv += "\(date),\(meal),\(food),\(portion),\(cal),\(protein),\(carbs),\(fat)\n"
        }

        return csv
    }

    static func exportURL(from entries: [FoodLogEntry]) -> URL? {
        let csv = generateCSV(from: entries)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("BiteLog_Export.csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
