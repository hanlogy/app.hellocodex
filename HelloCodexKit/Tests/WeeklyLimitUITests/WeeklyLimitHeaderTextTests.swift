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

private let resetsAt = stockholm.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: 9))!

/// A summary with only what the header shows.
private func summary(percentLeft: Double) -> WeeklySummary {
    WeeklySummary(
        percentLeft: percentLeft, week: Week(endingAt: resetsAt), runs: [], days: [], dayGroups: [],
        todayIndex: 0, versusEvenPace: 0, runsOutAt: nil,
        projectionEnd: ChartPoint(time: resetsAt, percentLeft: percentLeft))
}

private func text(
    percentLeft: Double, variant: Variant = .full,
    now: Date = resetsAt.addingTimeInterval(-(4 * 24 + 19.5) * 3600)
) -> WeeklyLimitHeaderText {
    WeeklyLimitHeaderText(
        summary: summary(percentLeft: percentLeft), variant: variant, now: now,
        locale: Locale(identifier: "en_GB"), calendar: stockholm)
}

struct WeeklyLimitHeaderTextTests {
    @Test func showsWhatIsLeftAndWhenTheLimitResets() {
        let header = text(percentLeft: 54)

        #expect(header.percentLeft == "54%")
        #expect(header.caption == "left this week")
        #expect(header.timeUntilReset == "4d 19h")
        #expect(header.resetsAt == "until reset · Fri 2 Oct, 09:00")
    }

    @Test func leavesOutTheResetDateWhenCompact() {
        let header = text(percentLeft: 54, variant: .compact)

        #expect(header.timeUntilReset == "4d 19h")
        #expect(header.resetsAt == "until reset")
    }

    @Test(arguments: [(21.0, false), (20.0, true), (3.0, true)])
    func warnsWhenLittleIsLeft(percentLeft: Double, isLow: Bool) {
        #expect(text(percentLeft: percentLeft).isLow == isLow)
    }

    @Test func countsDownToZeroOnceTheResetIsDue() {
        #expect(
            text(percentLeft: 54, now: resetsAt.addingTimeInterval(60)).timeUntilReset == "0h 0m")
    }
}
