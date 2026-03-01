import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }

    var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var shortFormatted: String {
        if isToday { return "Today" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: self)
    }

    var dayMonthFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    func daysFrom(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: self.startOfDay).day ?? 0
    }

    static func datesInRange(from start: Date, days: Int) -> [Date] {
        (0..<days).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: start.startOfDay)
        }
    }
}
