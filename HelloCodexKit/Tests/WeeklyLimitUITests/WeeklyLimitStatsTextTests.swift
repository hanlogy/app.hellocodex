import DesignSystem
import Foundation
import Testing
import WeeklyLimit

@testable import WeeklyLimitUI

private let stockholm: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return calendar
}()

private func local(_ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    stockholm.date(
        from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
}

private let resetsAt = local(10, 2, 9)

/// Three days, Thu to Sat, with today on Fri.
private func summary(
    dayGroups: [DayGroup] = [
        DayGroup(firstDay: 0, lastDay: 0, usedPercent: 9),
        DayGroup(firstDay: 1, lastDay: 1, usedPercent: 16),
        DayGroup(firstDay: 2, lastDay: 2, usedPercent: nil),
    ],
    runsOutAt: Date? = nil
) -> WeeklySummary {
    WeeklySummary(
        percentLeft: 54, week: Week(endingAt: resetsAt), runs: [],
        days: [
            DayUsage(startsAt: local(10, 1), usedPercent: 9),
            DayUsage(startsAt: local(10, 2), usedPercent: 16),
            DayUsage(startsAt: local(10, 3), usedPercent: nil),
        ],
        dayGroups: dayGroups, todayIndex: 1, versusEvenPace: -13.6, runsOutAt: runsOutAt,
        projectionEnd: ChartPoint(time: resetsAt, percentLeft: 10))
}

private func stats(_ summary: WeeklySummary) -> [Stat] {
    WeeklyLimitStatsText.stats(
        of: summary, locale: Locale(identifier: "en_GB"), calendar: stockholm)
}

struct WeeklyLimitStatsTextTests {
    @Test func showsTodaysUsageThePaceAndAGreenLastingProjection() {
        #expect(
            stats(summary()) == [
                Stat(label: "Today", value: "\u{2212}16%"),
                Stat(label: "Versus even pace", value: "\u{2212}14 pts"),
                Stat(label: "At this pace", value: "Lasts to reset", tone: .success),
            ])
    }

    @Test func labelsTodayWithItsRangeWhenEarlierDaysAreMergedIntoIt() {
        let merged = summary(dayGroups: [
            DayGroup(firstDay: 0, lastDay: 1, usedPercent: 25),
            DayGroup(firstDay: 2, lastDay: 2, usedPercent: nil),
        ])

        #expect(stats(merged)[0] == Stat(label: "Thu – Today", value: "\u{2212}25%"))
    }

    @Test func warnsWhenTheLimitRunsOut() {
        #expect(
            stats(summary(runsOutAt: local(9, 30, 4, 38)))[2]
                == Stat(label: "At this pace", value: "Runs out Wed 04:40", tone: .warning))
    }
}
