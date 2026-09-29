import Foundation
import Testing

@testable import DesignSystem

private let stockholm: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return calendar
}()

private func local(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    stockholm.date(
        from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

struct DisplayTextTests {
    @Test(arguments: [(53.6, "54%"), (79.4, "79%"), (0, "0%"), (100, "100%")])
    func roundsPercentages(value: Double, text: String) {
        #expect(DisplayText.percent(value) == text)
    }

    @Test(arguments: [
        (4.4, "+4 pts"), (-13.6, "\u{2212}14 pts"), (0, "+0 pts"), (13.5, "+14 pts"),
        (-13.5, "\u{2212}14 pts"),
    ])
    func signsPoints(value: Double, text: String) {
        #expect(DisplayText.signedPoints(value) == text)
    }

    private static let durations: [(TimeInterval, String)] = [
        ((4 * 24 + 19.5) * 3600, "4d 19h"), (5.2 * 3600, "5h 12m"), (59, "0h 0m"), (-1, "0h 0m"),
        (24 * 3600, "1d 0h"),
    ]

    @Test(arguments: durations)
    func showsDaysAndHoursOrHoursAndMinutesInTheLastDay(interval: TimeInterval, text: String) {
        #expect(DisplayText.duration(interval) == text)
    }

    @Test func formatsDatesLikeTheDesign() {
        #expect(
            DisplayText.dateTime(local(2026, 10, 2, 9), calendar: stockholm) == "Fri 2 Oct, 09:00")
    }

    @Test func abbreviatesEveryMonthToThreeLettersLikeTheDesign() {
        let months = (1...12).map {
            DisplayText.dateTime(local(2026, $0, 15, 12), calendar: stockholm)
        }

        #expect(
            months.map { $0.split(separator: " ")[2] } == [
                "Jan,", "Feb,", "Mar,", "Apr,", "May,", "Jun,", "Jul,", "Aug,", "Sep,", "Oct,",
                "Nov,", "Dec,",
            ])
    }

    @Test func roundsEstimatedTimesToTenMinutes() {
        #expect(
            DisplayText.estimatedTime(local(2026, 9, 30, 4, 43), calendar: stockholm) == "Wed 04:40"
        )
        #expect(
            DisplayText.estimatedTime(local(2026, 9, 30, 23, 56), calendar: stockholm)
                == "Thu 00:00")
    }

    @Test func namesTheWeekdayInEnglish() {
        #expect(DisplayText.weekday(local(2026, 9, 26, 12), calendar: stockholm) == "Sat")
    }
}
