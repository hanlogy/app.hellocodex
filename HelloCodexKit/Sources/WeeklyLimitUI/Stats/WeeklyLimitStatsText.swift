import DesignSystem
import Foundation
import WeeklyLimit

/// The stats below the chart: today's usage, the pace, and where it leads.
enum WeeklyLimitStatsText {
    static func stats(of summary: WeeklySummary, locale: Locale, calendar: Calendar) -> [Stat] {
        [
            today(summary, locale: locale, calendar: calendar),
            Stat(
                label: "Versus even pace",
                value: DisplayText.signedPoints(summary.versusEvenPace)),
            // Green when the limit lasts to the reset, orange when it runs out first.
            summary.runsOutAt.map {
                Stat(
                    label: "At this pace",
                    value: "Runs out "
                        + DisplayText.estimatedTime($0, locale: locale, calendar: calendar),
                    tone: .warning)
            } ?? Stat(label: "At this pace", value: "Lasts to reset", tone: .success),
        ]
    }

    /// Today's usage, labelled "Sat 26 – Today" when it also covers earlier
    /// days the app didn't record on.
    private static func today(
        _ summary: WeeklySummary, locale: Locale, calendar: Calendar
    ) -> Stat {
        guard let group = summary.dayGroups.first(where: { $0.lastDay == summary.todayIndex })
        else {
            return Stat(label: "Today", value: WeeklyLimitText.usedChange(0))
        }
        let labels = WeeklyLimitText.dayLabels(
            of: summary.days, todayIndex: summary.todayIndex, locale: locale, calendar: calendar)
        return Stat(
            label: WeeklyLimitText.label(of: group, dayLabels: labels),
            value: WeeklyLimitText.usedChange(group.usedPercent ?? 0))
    }
}
