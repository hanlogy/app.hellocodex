import DesignSystem
import Foundation
import WeeklyLimit

/// The header's text: how much is left this week, and when the limit resets.
struct WeeklyLimitHeaderText {
    /// At or below this much left, the percentage is shown as a warning.
    static let lowPercentLeft = 20.0

    let percentLeft: String
    let caption = "left this week"
    let timeUntilReset: String
    let resetsAt: String
    let isLow: Bool

    init(summary: WeeklySummary, now: Date, locale: Locale, calendar: Calendar) {
        percentLeft = DisplayText.percent(summary.percentLeft)
        timeUntilReset = DisplayText.duration(summary.week.resetsAt.timeIntervalSince(now))
        resetsAt =
            "until reset · "
            + DisplayText.dateTime(summary.week.resetsAt, locale: locale, calendar: calendar)
        isLow = summary.percentLeft <= Self.lowPercentLeft
    }
}
