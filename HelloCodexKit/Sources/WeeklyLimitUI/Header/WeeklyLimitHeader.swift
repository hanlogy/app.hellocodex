import DesignSystem
import SwiftUI
import WeeklyLimit

/// How much of the weekly limit is left, and how long until it resets.
public struct WeeklyLimitHeader: View {
    private let summary: WeeklySummary

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    public init(summary: WeeklySummary) {
        self.summary = summary
    }

    public var body: some View {
        // Redrawn every minute, so the time until the reset keeps counting down.
        TimelineView(.everyMinute) { context in
            let text = WeeklyLimitHeaderText(
                summary: summary, now: context.date, locale: locale, calendar: calendar)
            HStack(alignment: .lastTextBaseline, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(text.percentLeft, kerningBetweenCharacters: -3.6)
                        .font(.system(size: 72, weight: .light, design: .monospaced))
                        .foregroundStyle(text.isLow ? Theme.warning : Theme.text)
                    Text(text.caption)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(text.timeUntilReset)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.text)
                    Text(text.resetsAt)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .monospacedDigit()
        }
    }
}
