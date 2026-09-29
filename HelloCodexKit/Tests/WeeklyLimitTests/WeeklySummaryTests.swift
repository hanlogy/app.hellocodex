import Foundation
import Testing

@testable import WeeklyLimit

private let resetsAt = local(2026, 10, 2, 9)
private let now = local(2026, 9, 27, 14)

struct WeeklySummaryTests {
    @Test func isNilWhenCodexDoesNotSayWhenTheLimitResets() {
        let limit = WeeklyLimit(limitID: "codex", usedPercent: 10, resetsAt: nil)

        #expect(WeeklySummary(limit: limit, records: [], now: now, calendar: stockholm) == nil)
    }

    @Test func summarizesTheWeekUpToTheLatestReading() throws {
        let limit = WeeklyLimit(limitID: "codex", usedPercent: 46, resetsAt: resetsAt)
        let earlier = WeeklyLimitRecord(
            limit: WeeklyLimit(limitID: "codex", usedPercent: 40, resetsAt: resetsAt),
            recordedAt: now.addingTimeInterval(.minutes(-5)))

        let summary = try #require(
            WeeklySummary(limit: limit, records: [earlier], now: now, calendar: stockholm))

        #expect(summary.percentLeft == 54)
        #expect(summary.week == Week(endingAt: resetsAt))
        #expect(summary.todayIndex == 2)
        #expect(summary.runsOutAt != nil)
        // Nothing was recorded before today, so the week so far is one bar.
        #expect(summary.dayGroups.first == DayGroup(firstDay: 0, lastDay: 2, usedPercent: 46))
        // The latest reading ends the chart at now, even though it isn't stored.
        #expect(summary.runs.last?.last == ChartPoint(time: now, percentLeft: 54))
    }

    @Test func summarizesAWeekWithoutStoredReadings() throws {
        let limit = WeeklyLimit(limitID: "codex", usedPercent: 0, resetsAt: resetsAt)

        let summary = try #require(
            WeeklySummary(limit: limit, records: [], now: now, calendar: stockholm))

        #expect(summary.percentLeft == 100)
        #expect(summary.runsOutAt == nil)
        #expect(summary.projectionEnd == ChartPoint(time: resetsAt, percentLeft: 100))
    }

    @Test func startsTodayAtTheFirstDayRightAfterAReset() throws {
        // Right after a reset, Codex can put the next reset a moment more than
        // 7 days ahead, so now is just before the week start.
        let limit = WeeklyLimit(
            limitID: "codex", usedPercent: 0,
            resetsAt: now.addingTimeInterval(7 * 24 * 60 * 60 + 30))

        let summary = try #require(
            WeeklySummary(limit: limit, records: [], now: now, calendar: stockholm))

        #expect(summary.todayIndex == 0)
        #expect(summary.days.first?.usedPercent == 0)
    }
}
