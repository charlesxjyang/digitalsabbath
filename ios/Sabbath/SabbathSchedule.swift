import Foundation

struct SabbathSchedule {
    static let sabbathDates: [String] = [
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

    static func isUpcoming() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        for date in parsedDates {
            let sabbathStart = calendar.startOfDay(for: date)
            guard let cutoff = calendar.date(byAdding: .day, value: -60, to: sabbathStart) else { continue }
            if now >= cutoff && now < sabbathStart {
                return true
            }
        }
        return false
    }
}
