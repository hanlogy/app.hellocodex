import Foundation
import WeeklyLimit

/// The bars in "Used per day": one per day, or one wide bar across days the
/// app didn't record on.
struct WeeklyLimitDailyUsageData {
    struct Bar: Equatable {
        /// The first of the days it covers, as a column index.
        let firstDay: Int
        /// How many day columns it spans.
        let span: Int
        /// Its height as a share of the tallest bar, or nil for a day that
        /// hasn't started.
        let height: Double?
        let value: String
        let label: String
        let isToday: Bool
    }

    /// Bars never shrink below this, so a small day still shows.
    static let minimumHeight = 0.04

    /// One column per day of the week.
    let columns: Int
    let bars: [Bar]

    init(summary: WeeklySummary, locale: Locale, calendar: Calendar) {
        let labels = WeeklyLimitText.dayLabels(
            of: summary.days, todayIndex: summary.todayIndex, locale: locale, calendar: calendar)
        let maxUsed = summary.dayGroups.compactMap(\.usedPercent).max() ?? 0
        columns = summary.days.count
        bars = summary.dayGroups.map { group in
            Bar(
                firstDay: group.firstDay,
                span: group.lastDay - group.firstDay + 1,
                // A day whose usage went down has nothing to show above zero.
                height: group.usedPercent.map {
                    max(Self.minimumHeight, maxUsed > 0 ? max(0, $0) / maxUsed : 0)
                },
                value: group.usedPercent.map(WeeklyLimitText.usedChange) ?? "—",
                label: WeeklyLimitText.label(of: group, dayLabels: labels),
                isToday: group.lastDay == summary.todayIndex)
        }
    }
}
