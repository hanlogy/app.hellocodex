import DesignSystem
import SwiftUI
import WeeklyLimit

/// Today's usage, how it compares with an even pace, and whether the limit
/// lasts at this pace.
public struct WeeklyLimitStats: View {
    private let summary: WeeklySummary

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    public init(summary: WeeklySummary) {
        self.summary = summary
    }

    public var body: some View {
        StatRow(WeeklyLimitStatsText.stats(of: summary, locale: locale, calendar: calendar))
    }
}
