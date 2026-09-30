import Foundation
import Testing
import WeeklyLimit

@testable import WeeklyLimitUI

private let stockholm: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return calendar
}()

private func at(_ day: Int, _ hour: Int) -> Date {
    stockholm.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
}

/// The week from Fri 25 Sep 09:00 to Fri 2 Oct 09:00.
private let week = Week(
    endingAt: stockholm.date(
        from: DateComponents(year: 2026, month: 10, day: 2, hour: 9))!)

private func point(_ time: Date, _ percentLeft: Double) -> ChartPoint {
    ChartPoint(time: time, percentLeft: percentLeft)
}

/// A summary with only what the chart draws.
private func summary(
    runs: [[ChartPoint]], days: [DayUsage] = [], todayIndex: Int = 0,
    runsOutAt: Date? = nil, projectionEnd: ChartPoint? = nil
) -> WeeklySummary {
    WeeklySummary(
        percentLeft: runs.last?.last?.percentLeft ?? 100, week: week, runs: runs, days: days,
        dayGroups: [], todayIndex: todayIndex, versusEvenPace: 0, runsOutAt: runsOutAt,
        projectionEnd: projectionEnd ?? point(week.resetsAt, 0))
}

private func data(_ summary: WeeklySummary) -> WeeklyLimitChartData {
    WeeklyLimitChartData(summary: summary, locale: Locale(identifier: "en_GB"), calendar: stockholm)
}

struct WeeklyLimitChartDataTests {
    @Test func joinsTheEndOfEachRunToTheStartOfTheNext() {
        let first = [point(week.startsAt, 100), point(at(25, 12), 90)]
        let second = [point(at(26, 10), 80), point(at(26, 11), 75)]
        let third = [point(at(27, 10), 60)]

        let chart = data(summary(runs: [first, second, third]))

        #expect(chart.runs == [first, second, third])
        #expect(
            chart.gaps == [
                [point(at(25, 12), 90), point(at(26, 10), 80)],
                [point(at(26, 11), 75), point(at(27, 10), 60)],
            ])
    }

    @Test func hasNoGapsWhenTheAppRanAllWeek() {
        #expect(
            data(summary(runs: [[point(week.startsAt, 100), point(at(26, 10), 80)]])).gaps == [])
    }

    @Test func drawsTheEvenPaceFromTheWeekStartToTheReset() {
        #expect(
            data(summary(runs: [])).evenPace == [
                point(week.startsAt, 100), point(week.resetsAt, 0),
            ])
    }

    @Test func projectsFromTheLatestReadingAndWarnsWhenItRunsOut() {
        let latest = point(at(28, 10), 40)
        let end = point(at(30, 6), 0)

        let chart = data(
            summary(
                runs: [[point(week.startsAt, 100), latest]], runsOutAt: end.time, projectionEnd: end
            ))

        #expect(chart.latest == latest)
        #expect(chart.projection == [latest, end])
        #expect(chart.runsOut)
    }

    @Test func doesNotWarnWhenTheLimitLasts() {
        let chart = data(
            summary(
                runs: [[point(week.startsAt, 100)]], projectionEnd: point(week.resetsAt, 60)))

        #expect(!chart.runsOut)
    }

    @Test func hasNothingToMarkOrProjectWithoutReadings() {
        let chart = data(summary(runs: []))

        #expect(chart.latest == nil)
        #expect(chart.projection == [])
    }

    @Test func ticksEachMidnightWithItsWeekdayOrToday() {
        let days = [week.startsAt, at(26, 0), at(27, 0), at(28, 0)].map {
            DayUsage(startsAt: $0, usedPercent: 0)
        }

        let ticks = data(summary(runs: [], days: days, todayIndex: 2)).ticks

        #expect(ticks.map(\.label) == ["Sat", "Today", "Mon"])
        #expect(ticks.map(\.isToday) == [false, true, false])
        #expect(ticks.map(\.time) == [at(26, 0), at(27, 0), at(28, 0)])
    }
}
