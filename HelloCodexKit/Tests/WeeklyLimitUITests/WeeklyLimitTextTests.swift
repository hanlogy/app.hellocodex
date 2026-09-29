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

/// The week from Fri 25 Sep 09:00 to Fri 2 Oct 09:00.
private let days =
    ([local(9, 25, 9)] + (26...30).map { local(9, $0) } + [local(10, 1), local(10, 2)])
    .map { DayUsage(startsAt: $0, usedPercent: nil) }

struct WeeklyLimitTextTests {
    @Test(arguments: [(16.2, "\u{2212}16%"), (0.2, "0%"), (0, "0%")])
    func showsUsageAsADecreaseInWhatIsLeft(usedPercent: Double, text: String) {
        #expect(WeeklyLimitText.usedChange(usedPercent) == text)
    }

    @Test func showsLowerUsageAsAnIncreaseInWhatIsLeft() {
        #expect(WeeklyLimitText.usedChange(-3.2) == "+3%")
    }

    @Test func namesTodayAndDatesTheWeekdayThatAppearsTwice() {
        #expect(
            WeeklyLimitText.dayLabels(
                of: days, todayIndex: 2, locale: Locale(identifier: "en_GB"), calendar: stockholm)
                == ["Fri 25", "Sat", "Today", "Mon", "Tue", "Wed", "Thu", "Fri 2"])
    }

    @Test func labelsAGroupByItsDayOrItsRange() {
        let labels = ["Fri 25", "Sat", "Today"]

        #expect(
            WeeklyLimitText.label(
                of: DayGroup(firstDay: 1, lastDay: 1, usedPercent: 4), dayLabels: labels) == "Sat")
        #expect(
            WeeklyLimitText.label(
                of: DayGroup(firstDay: 1, lastDay: 2, usedPercent: 4), dayLabels: labels)
                == "Sat – Today")
    }
}
