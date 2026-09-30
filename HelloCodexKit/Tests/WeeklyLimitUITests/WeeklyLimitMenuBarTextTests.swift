import Foundation
import Testing
import WeeklyLimit

@testable import WeeklyLimitUI

private let resetsAt = Date(timeIntervalSince1970: 1_791_047_411)

/// A summary of three days, with today the second, in these groups.
private func summary(_ dayGroups: [DayGroup]) -> WeeklySummary {
    let start = resetsAt.addingTimeInterval(-7 * 24 * 3600)
    return WeeklySummary(
        percentLeft: 68, week: Week(endingAt: resetsAt), runs: [],
        days: [
            DayUsage(startsAt: start, usedPercent: 10),
            DayUsage(startsAt: start.addingTimeInterval(86_400), usedPercent: 3),
            DayUsage(startsAt: start.addingTimeInterval(2 * 86_400), usedPercent: nil),
        ],
        dayGroups: dayGroups, todayIndex: 1, versusEvenPace: 0, runsOutAt: nil,
        projectionEnd: ChartPoint(time: resetsAt, percentLeft: 40))
}

/// Separate groups for the first day, today used as given, and the last day.
private func summary(todayUsed: Double) -> WeeklySummary {
    summary([
        DayGroup(firstDay: 0, lastDay: 0, usedPercent: 10),
        DayGroup(firstDay: 1, lastDay: 1, usedPercent: todayUsed),
        DayGroup(firstDay: 2, lastDay: 2, usedPercent: nil),
    ])
}

struct WeeklyLimitMenuBarTextTests {
    @Test func showsNothingUntilTheLimitIsKnown() {
        #expect(WeeklyLimitMenuBarText.text(percentLeft: nil, summary: nil) == nil)
    }

    @Test func showsWhatIsLeftBeforeThereIsASummary() {
        #expect(WeeklyLimitMenuBarText.text(percentLeft: 68, summary: nil) == "68%")
    }

    @Test func addsWhatTodayUsed() {
        let text = WeeklyLimitMenuBarText.text(
            percentLeft: 68,
            summary: summary(todayUsed: 3.2))

        #expect(text == "68% (\u{2212}3%)")
    }

    @Test func leavesOutTodayUntilItUsedAPercent() {
        let text = WeeklyLimitMenuBarText.text(
            percentLeft: 68,
            summary: summary(todayUsed: 0.4))

        #expect(text == "68%")
    }

    /// Days the app didn't record on count toward today, as in the stats.
    @Test func countsDaysMergedIntoToday() {
        let text = WeeklyLimitMenuBarText.text(
            percentLeft: 68,
            summary: summary([
                DayGroup(firstDay: 0, lastDay: 1, usedPercent: 13),
                DayGroup(firstDay: 2, lastDay: 2, usedPercent: nil),
            ]))

        #expect(text == "68% (\u{2212}13%)")
    }
}
