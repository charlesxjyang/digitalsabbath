import Foundation

struct SabbathSchedule {
    static let sabbathDates: [String] = [
        "2026-02-16", // Testing
        "2026-06-21", // Summer solstice
    ]

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private static var parsedDates: [Date] {
        sabbathDates.compactMap { formatter.date(from: $0) }
    }

    static func isSabbathActive() -> Bool {
        let today = formatter.string(from: Date())
        return sabbathDates.contains(today)
    }

    static func nextSabbathDate() -> Date? {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        return parsedDates
            .filter { $0 >= startOfToday }
            .sorted()
            .first
    }
}
