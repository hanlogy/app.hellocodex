import DesignSystem
import SwiftUI
import WeeklyLimit

/// Today's usage, how it compares with an even pace, and whether the limit
/// lasts at this pace.
public struct WeeklyLimitStats: View {
    private let summary: WeeklySummary
    private let variant: Variant

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    /// The compact variant shows one stat per line.
    public init(summary: WeeklySummary, variant: Variant = .full) {
        self.summary = summary
        self.variant = variant
    }

    public var body: some View {
        StatRow(
            WeeklyLimitStatsText.stats(of: summary, locale: locale, calendar: calendar),
            variant: variant)
    }
}
