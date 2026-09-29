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

    /// The compact variant leaves out the reset date.
    init(
        summary: WeeklySummary, variant: Variant, now: Date, locale: Locale, calendar: Calendar
    ) {
        percentLeft = DisplayText.percent(summary.percentLeft)
        timeUntilReset = DisplayText.duration(summary.week.resetsAt.timeIntervalSince(now))
        switch variant {
        case .full:
            resetsAt =
                "until reset · "
                + DisplayText.dateTime(summary.week.resetsAt, locale: locale, calendar: calendar)
        case .compact:
            resetsAt = "until reset"
        }
        isLow = summary.percentLeft <= Self.lowPercentLeft
    }
}
