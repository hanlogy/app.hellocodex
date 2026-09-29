import Foundation

/// A calendar month in UTC, which names a monthly file.
struct Month: Comparable {
    let year: Int
    let month: Int

    /// "2026-09".
    var name: String {
        String(format: "%04d-%02d", year, month)
    }

    var next: Month {
        month == 12 ? Month(year: year + 1, month: 1) : Month(year: year, month: month + 1)
    }

    /// Every month from the one containing `start` to the one containing `end`,
    /// or none when `end` is before `start`.
    static func range(from start: Date, to end: Date) -> [Month] {
        let last = Month(containing: end)
        var months: [Month] = []
        var current = Month(containing: start)
        while current <= last {
            months.append(current)
            current = current.next
        }
        return months
    }

    static func < (lhs: Month, rhs: Month) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    fileprivate static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
}

extension Month {
    init(containing date: Date) {
        let components = Self.calendar.dateComponents([.year, .month], from: date)
        self.init(year: components.year ?? 0, month: components.month ?? 0)
    }
}
