import Foundation
import Testing

@testable import WeeklyLimit

private let week = Week(endingAt: local(2026, 10, 2, 9))

private func at(minutes: Double) -> Date {
    week.startsAt.addingTimeInterval(.minutes(minutes))
}

struct ChartPointTests {
    @Test func startsTheFirstRunAtFullWhenTheAppRanFromTheWeekStart() {
        let runs = ChartPoint.runs(
            of: [
                UsagePoint(time: at(minutes: 10), usedPercent: 2),
                UsagePoint(time: at(minutes: 20), usedPercent: 5),
            ], in: week)

        #expect(
            runs == [
                [
                    ChartPoint(time: week.startsAt, percentLeft: 100),
                    ChartPoint(time: at(minutes: 10), percentLeft: 98),
                    ChartPoint(time: at(minutes: 20), percentLeft: 95),
                ]
            ])
    }

    @Test func startsANewRunAfterAGap() {
        let afterGap = at(minutes: 20).addingTimeInterval(ChartPoint.gap + 1)

        let runs = ChartPoint.runs(
            of: [
                UsagePoint(time: at(minutes: 10), usedPercent: 2),
                UsagePoint(time: at(minutes: 20), usedPercent: 5),
                UsagePoint(time: afterGap, usedPercent: 9),
            ], in: week)

        #expect(runs.map(\.count) == [3, 1])
        #expect(runs.last == [ChartPoint(time: afterGap, percentLeft: 91)])
    }

    @Test func keepsReadingsExactlyAGapApartInOneRun() {
        let runs = ChartPoint.runs(
            of: [
                UsagePoint(time: at(minutes: 0).addingTimeInterval(ChartPoint.gap), usedPercent: 1)
            ],
            in: week)

        #expect(runs.count == 1)
    }

    @Test func keepsTheWeekStartOnItsOwnWhenTheFirstReadingIsLater() {
        let runs = ChartPoint.runs(
            of: [UsagePoint(time: at(minutes: 60), usedPercent: 4)], in: week)

        #expect(
            runs == [
                [ChartPoint(time: week.startsAt, percentLeft: 100)],
                [ChartPoint(time: at(minutes: 60), percentLeft: 96)],
            ])
    }

    @Test func hasOnlyTheWeekStartWithoutReadings() {
        #expect(
            ChartPoint.runs(of: [], in: week) == [
                [ChartPoint(time: week.startsAt, percentLeft: 100)]
            ])
    }
}
