import Foundation
import Testing

@testable import WeeklyLimit

private let week = Week(endingAt: Date(timeIntervalSince1970: .hours(168)))

private func after(hours: Double) -> Date {
    week.startsAt.addingTimeInterval(.hours(hours))
}

struct PaceTests {
    @Test func comparesThePercentLeftWithAnEvenPace() {
        #expect(Pace.versusEvenPace(percentLeft: 54, in: week, at: after(hours: 84)) == 4)
        #expect(Pace.versusEvenPace(percentLeft: 40, in: week, at: after(hours: 84)) == -10)
    }

    @Test func projectsWhenThisWeeksAverageRateUsesUpTheLimit() {
        // 50% in 40 hours runs out 40 hours later.
        #expect(Pace.runsOutAt(usedPercent: 50, in: week, at: after(hours: 40)) == after(hours: 80))
    }

    @Test func runsOutNowWhenTheLimitIsUsedUp() {
        #expect(
            Pace.runsOutAt(usedPercent: 100, in: week, at: after(hours: 40)) == after(hours: 40))
    }

    @Test func doesNotRunOutWhenTheLimitLastsUntilTheReset() {
        #expect(Pace.runsOutAt(usedPercent: 20, in: week, at: after(hours: 84)) == nil)
    }

    @Test func doesNotRunOutBeforeAnyUsage() {
        #expect(Pace.runsOutAt(usedPercent: 0, in: week, at: after(hours: 10)) == nil)
    }

    @Test func doesNotRunOutAtTheWeekStart() {
        #expect(Pace.runsOutAt(usedPercent: 5, in: week, at: week.startsAt) == nil)
    }

    @Test func endsTheProjectionAtZeroWhenTheLimitRunsOut() {
        #expect(
            Pace.projectionEnd(usedPercent: 50, in: week, at: after(hours: 40))
                == ChartPoint(time: after(hours: 80), percentLeft: 0))
    }

    @Test func endsTheProjectionAtTheResetWhenTheLimitLasts() {
        // 20% in 84 hours leaves 60% after the other 84 hours.
        #expect(
            Pace.projectionEnd(usedPercent: 20, in: week, at: after(hours: 84))
                == ChartPoint(time: week.resetsAt, percentLeft: 60))
    }
}
