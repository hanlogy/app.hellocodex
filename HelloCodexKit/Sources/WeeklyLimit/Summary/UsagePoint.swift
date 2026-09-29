import Foundation

/// A reading of how much of the limit was used at a time.
struct UsagePoint: Equatable {
    let time: Date
    let usedPercent: Double
}

extension UsagePoint {
    /// Readings of one limit from the week start until now, oldest first.
    static func points(
        from records: [WeeklyLimitRecord], limitID: String, in week: Week, until now: Date
    ) -> [UsagePoint] {
        records
            .filter {
                $0.limitID == limitID && $0.recordedAt >= week.startsAt && $0.recordedAt <= now
            }
            .map { UsagePoint(time: $0.recordedAt, usedPercent: $0.usedPercent) }
            .sorted { $0.time < $1.time }
    }
}

extension [UsagePoint] {
    /// The last known usage at `time`. Usage is 0 when the week starts, so
    /// times before the first reading count as 0. The points must be oldest
    /// first.
    func used(at time: Date) -> Double {
        last { $0.time <= time }?.usedPercent ?? 0
    }
}
