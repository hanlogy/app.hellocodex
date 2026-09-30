import DesignSystem
import Foundation
import WeeklyLimit

/// Text about the weekly limit's usage, shared by its sections.
enum WeeklyLimitText {
    /// Usage takes away from what's left, so it's shown as a decrease: "−16%".
    /// Lower usage leaves more, so it's an increase: "+3%".
    static func usedChange(_ usedPercent: Double) -> String {
        let rounded = Int(usedPercent.rounded())
        return rounded == 0 ? "0%" : "\(rounded > 0 ? DisplayText.minus : "+")\(abs(rounded))%"
    }

    /// A label per day: "Today", else the weekday, with the date added when the
    /// weekday appears twice in the week ("Fri 25" … "Fri 2").
    static func dayLabels(
        of days: [DayUsage], todayIndex: Int, locale: Locale, calendar: Calendar
    ) -> [String] {
        let weekdays = days.map {
            DisplayText.weekday($0.startsAt, locale: locale, calendar: calendar)
        }
        return days.indices.map { index in
            if index == todayIndex {
                return "Today"
            }
            let isRepeated = weekdays.filter { $0 == weekdays[index] }.count > 1
            return isRepeated
                ? DisplayText.weekdayAndDay(
                    days[index].startsAt, locale: locale, calendar: calendar)
                : weekdays[index]
        }
    }

    /// The group that ends today: today alone, or with the earlier days the app
    /// didn't record on.
    static func todayGroup(of summary: WeeklySummary) -> DayGroup? {
        summary.dayGroups.first { $0.lastDay == summary.todayIndex }
    }

    /// "Tue", or "Sat 26 – Today" for days merged into one group.
    static func label(of group: DayGroup, dayLabels: [String]) -> String {
        group.firstDay == group.lastDay
            ? dayLabels[group.firstDay]
            : "\(dayLabels[group.firstDay]) – \(dayLabels[group.lastDay])"
    }
}
