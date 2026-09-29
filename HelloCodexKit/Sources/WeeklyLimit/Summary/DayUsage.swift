import Foundation

/// How much of the limit was used on one calendar day of the week.
public struct DayUsage: Equatable, Sendable {
    /// Midnight, or the week start for the first day.
    public let startsAt: Date
    /// nil for a day that hasn't started yet.
    public let usedPercent: Double?

    public init(startsAt: Date, usedPercent: Double?) {
        self.startsAt = startsAt
        self.usedPercent = usedPercent
    }
}

extension DayUsage {
    /// Usage per calendar day. A reading after a gap counts toward the day it
    /// was read on, since that's when the change was seen; day groups then
    /// merge the days without readings into it.
    static func days(
        of points: [UsagePoint], in week: Week, until now: Date, calendar: Calendar
    ) -> [DayUsage] {
        let starts = week.dayStarts(in: calendar)
        return starts.indices.map { index in
            let startsAt = starts[index]
            // The first day has always started: right after a reset, Codex can
            // put the next reset a moment more than 7 days ahead.
            guard index == 0 || startsAt <= now else {
                return DayUsage(startsAt: startsAt, usedPercent: nil)
            }
            let endsAt = min(index + 1 < starts.count ? starts[index + 1] : week.resetsAt, now)
            return DayUsage(
                startsAt: startsAt, usedPercent: points.used(at: endsAt) - points.used(at: startsAt)
            )
        }
    }

    /// Today is the last day that has started.
    static func todayIndex(of days: [DayUsage]) -> Int {
        (days.firstIndex { $0.usedPercent == nil } ?? days.count) - 1
    }

    /// Whether the app recorded at least one reading on each day.
    static func haveReadings(_ days: [DayUsage], points: [UsagePoint], in week: Week) -> [Bool] {
        days.indices.map { index in
            let startsAt = days[index].startsAt
            let endsAt = index + 1 < days.count ? days[index + 1].startsAt : week.resetsAt
            return points.contains { $0.time >= startsAt && $0.time < endsAt }
        }
    }
}
