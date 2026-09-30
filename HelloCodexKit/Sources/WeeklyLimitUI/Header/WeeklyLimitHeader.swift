import DesignSystem
import SwiftUI
import WeeklyLimit

/// How much of the weekly limit is left, and how long until it resets.
public struct WeeklyLimitHeader: View {
    private let summary: WeeklySummary
    private let variant: Variant

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    /// The compact variant has smaller type and leaves out the reset date.
    public init(summary: WeeklySummary, variant: Variant = .full) {
        self.summary = summary
        self.variant = variant
    }

    public var body: some View {
        let isFull = variant == .full
        // Redrawn every minute, so the time until the reset keeps counting down.
        TimelineView(.everyMinute) { context in
            let text = WeeklyLimitHeaderText(
                summary: summary, variant: variant, now: context.date, locale: locale,
                calendar: calendar)
            HStack(alignment: .lastTextBaseline, spacing: 24) {
                VStack(alignment: .leading, spacing: isFull ? 8 : 6) {
                    Text(text.percentLeft)
                        .font(.system(size: isFull ? 72 : 38, weight: .light))
                        .foregroundStyle(text.isLow ? Theme.warning : Theme.text)
                    Text(text.caption)
                        .font(.system(size: isFull ? 13 : 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: isFull ? 4 : 3) {
                    Text(text.timeUntilReset)
                        .font(.system(size: isFull ? 15 : 12.5, weight: .medium))
                        .foregroundStyle(Theme.text)
                    Text(text.resetsAt)
                        .font(.system(size: isFull ? 12 : 11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .monospacedDigit()
        }
    }
}
