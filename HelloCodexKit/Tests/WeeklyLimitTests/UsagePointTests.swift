import Foundation
import Testing

@testable import WeeklyLimit

private let week = Week(endingAt: local(2026, 10, 2, 9))

private func record(_ time: Date, _ used: Double, limitID: String = "codex") -> WeeklyLimitRecord {
    WeeklyLimitRecord(
        limit: WeeklyLimit(limitID: limitID, usedPercent: used, resetsAt: week.resetsAt),
        recordedAt: time)
}

struct UsagePointTests {
    @Test func keepsThisLimitsReadingsFromTheWeekStartUntilNowOldestFirst() {
        let points = UsagePoint.points(
            from: [
                record(local(2026, 9, 26, 10), 20),
                record(local(2026, 9, 24, 10), 90),  // last week
                record(local(2026, 9, 25, 10), 5),
                record(local(2026, 9, 25, 11), 7, limitID: "other"),
                record(local(2026, 9, 27, 15), 30),  // after now
            ],
            limitID: "codex", in: week, until: local(2026, 9, 27, 14))

        #expect(
            points == [
                UsagePoint(time: local(2026, 9, 25, 10), usedPercent: 5),
                UsagePoint(time: local(2026, 9, 26, 10), usedPercent: 20),
            ])
    }

    @Test func countsUsageBeforeTheFirstReadingAsZero() {
        let points = [UsagePoint(time: local(2026, 9, 26), usedPercent: 5)]

        #expect(points.used(at: local(2026, 9, 25, 12)) == 0)
    }

    @Test func usesTheLastReadingAtOrBeforeTheTime() {
        let first = local(2026, 9, 26, 10)
        let second = local(2026, 9, 26, 12)
        let points = [
            UsagePoint(time: first, usedPercent: 5), UsagePoint(time: second, usedPercent: 12),
        ]

        #expect(points.used(at: first) == 5)
        #expect(points.used(at: second.addingTimeInterval(-1)) == 5)
        #expect(points.used(at: local(2026, 9, 27)) == 12)
    }
}
