import DesignSystem
import Foundation
import WeeklyLimit

/// What the chart draws, from 100% left at the week start to the reset.
struct WeeklyLimitChartData {
    /// A tick at a midnight, below the chart.
    struct Tick: Equatable {
        let time: Date
        let label: String
        let isToday: Bool
    }

    let week: Week
    /// Recorded readings, each run drawn as steps.
    let runs: [[ChartPoint]]
    /// Straight lines from the end of each run to the start of the next, where
    /// the app wasn't running.
    let gaps: [[ChartPoint]]
    /// From 100% at the week start to 0% at the reset.
    let evenPace: [ChartPoint]
    /// From the latest reading to where this week's average rate leads.
    let projection: [ChartPoint]
    /// The latest reading, marked as now.
    let latest: ChartPoint?
    /// Whether the projection runs out before the reset.
    let runsOut: Bool
    let ticks: [Tick]

    init(summary: WeeklySummary, locale: Locale, calendar: Calendar) {
        let week = summary.week
        self.week = week
        runs = summary.runs
        gaps = zip(summary.runs, summary.runs.dropFirst()).compactMap { previous, next in
            guard let from = previous.last, let to = next.first else {
                return nil
            }
            return [from, to]
        }
        evenPace = [
            ChartPoint(time: week.startsAt, percentLeft: 100),
            ChartPoint(time: week.resetsAt, percentLeft: 0),
        ]
        latest = summary.runs.last?.last
        projection = latest.map { [$0, summary.projectionEnd] } ?? []
        runsOut = summary.runsOutAt != nil
        // The first day starts with the week, at the chart's left edge.
        ticks = summary.days.indices.dropFirst().map { index in
            let time = summary.days[index].startsAt
            let isToday = index == summary.todayIndex
            return Tick(
                time: time,
                label: isToday
                    ? "Today" : DisplayText.weekday(time, locale: locale, calendar: calendar),
                isToday: isToday)
        }
    }
}
