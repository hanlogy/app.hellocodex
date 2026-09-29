import Foundation
import Testing
import WeeklyLimit

@testable import WeeklyLimitUI

private let stockholm: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return calendar
}()

private func local(_ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
    stockholm.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
}

private let resetsAt = local(10, 2, 9)

/// The week from Fri 25 Sep 09:00 to Fri 2 Oct 09:00, with today on Mon.
private let days =
    ([local(9, 25, 9)] + (26...30).map { local(9, $0) } + [local(10, 1), local(10, 2)])
    .enumerated().map { DayUsage(startsAt: $1, usedPercent: $0 <= 3 ? 1 : nil) }

private func data(_ dayGroups: [DayGroup]) -> WeeklyLimitDailyUsageData {
    WeeklyLimitDailyUsageData(
        summary: WeeklySummary(
            percentLeft: 54, week: Week(endingAt: resetsAt), runs: [], days: days,
            dayGroups: dayGroups, todayIndex: 3, versusEvenPace: 0, runsOutAt: nil,
            projectionEnd: ChartPoint(time: resetsAt, percentLeft: 10)),
        locale: Locale(identifier: "en_GB"), calendar: stockholm)
}

/// Groups for Fri 25 and Sat, Sun merged into today, and the later days.
private func groups(_ friday: Double, _ throughToday: Double) -> [DayGroup] {
    [
        DayGroup(firstDay: 0, lastDay: 0, usedPercent: friday),
        DayGroup(firstDay: 1, lastDay: 3, usedPercent: throughToday),
    ] + (4...7).map { DayGroup(firstDay: $0, lastDay: $0, usedPercent: nil) }
}

struct WeeklyLimitDailyUsageDataTests {
    @Test func hasAColumnPerDayAndABarAcrossMergedDays() {
        let usage = data(groups(8, 16))

        #expect(usage.columns == 8)
        #expect(usage.bars.map(\.firstDay) == [0, 1, 4, 5, 6, 7])
        #expect(usage.bars.map(\.span) == [1, 3, 1, 1, 1, 1])
    }

    @Test func hasSevenColumnsWhenTheWeekStartsAtMidnight() {
        let startsAt = local(9, 25)
        let resetsAt = local(10, 2)
        let days = (0..<7).map {
            DayUsage(
                startsAt: stockholm.date(byAdding: .day, value: $0, to: startsAt)!,
                usedPercent: nil)
        }

        let usage = WeeklyLimitDailyUsageData(
            summary: WeeklySummary(
                percentLeft: 100, week: Week(endingAt: resetsAt), runs: [], days: days,
                dayGroups: (0..<7).map { DayGroup(firstDay: $0, lastDay: $0, usedPercent: nil) },
                todayIndex: 0, versusEvenPace: 0, runsOutAt: nil,
                projectionEnd: ChartPoint(time: resetsAt, percentLeft: 100)),
            locale: Locale(identifier: "en_GB"), calendar: stockholm)

        #expect(usage.columns == 7)
    }

    @Test func labelsAndValuesEachBar() {
        let bars = data(groups(8, 16)).bars

        #expect(bars.map(\.label) == ["Fri 25", "Sat – Today", "Tue", "Wed", "Thu", "Fri 2"])
        #expect(bars.map(\.value) == ["\u{2212}8%", "\u{2212}16%", "—", "—", "—", "—"])
        #expect(bars.map(\.isToday) == [false, true, false, false, false, false])
    }

    @Test func sizesBarsAgainstTheTallestAndLeavesLaterDaysEmpty() {
        #expect(data(groups(8, 16)).bars.map(\.height) == [0.5, 1, nil, nil, nil, nil])
    }

    @Test func keepsASmallDayVisible() {
        #expect(data(groups(0, 16)).bars[0].height == WeeklyLimitDailyUsageData.minimumHeight)
    }

    @Test func showsADayWhoseUsageWentDownAsTheSmallestBar() {
        let bars = data(groups(-3, 16)).bars

        #expect(bars[0].height == WeeklyLimitDailyUsageData.minimumHeight)
        #expect(bars[0].value == "+3%")
    }

    @Test func keepsBarsVisibleBeforeAnyUsage() {
        let minimum = WeeklyLimitDailyUsageData.minimumHeight

        #expect(data(groups(0, 0)).bars.map(\.height).prefix(2) == [minimum, minimum])
    }
}
