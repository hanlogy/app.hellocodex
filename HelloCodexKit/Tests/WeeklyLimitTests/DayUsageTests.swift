import Foundation
import Testing

@testable import WeeklyLimit

private let week = Week(endingAt: local(2026, 10, 2, 9))

struct DayUsageTests {
    private let points = [
        UsagePoint(time: local(2026, 9, 25, 12), usedPercent: 9),
        UsagePoint(time: local(2026, 9, 26, 20), usedPercent: 30),
        // The app didn't run overnight; this change counts toward the 27th.
        UsagePoint(time: local(2026, 9, 27, 10), usedPercent: 38),
        UsagePoint(time: local(2026, 9, 27, 14), usedPercent: 46),
    ]

    @Test func showsTheUsageOfEachDaySoFarAndNothingForLaterDays() {
        let days = DayUsage.days(
            of: points, in: week, until: local(2026, 9, 27, 14), calendar: stockholm)

        #expect(days.map(\.usedPercent) == [9, 21, 16, nil, nil, nil, nil, nil])
    }

    @Test func findsTodayAsTheLastDayThatHasStarted() {
        let days = DayUsage.days(
            of: points, in: week, until: local(2026, 9, 27, 14), calendar: stockholm)

        #expect(DayUsage.todayIndex(of: days) == 2)
    }

    @Test func findsTodayOnTheLastDayOfTheWeek() {
        let days = DayUsage.days(
            of: points, in: week, until: local(2026, 10, 2, 8), calendar: stockholm)

        #expect(DayUsage.todayIndex(of: days) == days.count - 1)
    }

    @Test func marksTheDaysTheAppRecordedOn() {
        let days = DayUsage.days(
            of: [], in: week, until: local(2026, 9, 27, 14), calendar: stockholm)

        let haveReadings = DayUsage.haveReadings(
            days,
            points: [
                UsagePoint(time: local(2026, 9, 25, 12), usedPercent: 9),
                UsagePoint(time: local(2026, 9, 27, 10), usedPercent: 38),
            ], in: week)

        #expect(Array(haveReadings.prefix(3)) == [true, false, true])
    }

    @Test func countsTheLongDayWhenTheClocksGoBack() {
        // Sunday 25 October 2026 has 25 hours in Stockholm.
        let week = Week(endingAt: local(2026, 10, 28, 9))
        let points = [
            UsagePoint(time: local(2026, 10, 24, 23), usedPercent: 10),
            UsagePoint(time: local(2026, 10, 25, 23, 30), usedPercent: 25),
        ]

        let days = DayUsage.days(
            of: points, in: week, until: local(2026, 10, 26, 12), calendar: stockholm)

        #expect(days.map(\.startsAt).contains(local(2026, 10, 25)))
        #expect(days.first { $0.startsAt == local(2026, 10, 25) }?.usedPercent == 15)
    }
}
