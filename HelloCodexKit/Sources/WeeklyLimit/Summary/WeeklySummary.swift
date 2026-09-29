import Foundation

/// Everything the app shows about the current week.
public struct WeeklySummary: Equatable, Sendable {
    public let percentLeft: Double
    public let week: Week
    /// Recorded readings, split where the app wasn't running. Each run is a
    /// step line; consecutive runs are joined by a dashed line.
    public let runs: [[ChartPoint]]
    public let days: [DayUsage]
    public let dayGroups: [DayGroup]
    /// Index in ``days`` of today, the last day that has started.
    public let todayIndex: Int
    /// Points left above (+) or below (−) an even pace.
    public let versusEvenPace: Double
    /// When this week's average rate uses up the limit, or nil if it lasts.
    public let runsOutAt: Date?
    /// The end of the projection line, which starts at the latest reading.
    public let projectionEnd: ChartPoint

    public init(
        percentLeft: Double,
        week: Week,
        runs: [[ChartPoint]],
        days: [DayUsage],
        dayGroups: [DayGroup],
        todayIndex: Int,
        versusEvenPace: Double,
        runsOutAt: Date?,
        projectionEnd: ChartPoint
    ) {
        self.percentLeft = percentLeft
        self.week = week
        self.runs = runs
        self.days = days
        self.dayGroups = dayGroups
        self.todayIndex = todayIndex
        self.versusEvenPace = versusEvenPace
        self.runsOutAt = runsOutAt
        self.projectionEnd = projectionEnd
    }
}

extension WeeklySummary {
    /// Summarizes the week from the latest reading and the stored records, or
    /// nil when Codex doesn't say when the limit resets.
    init?(limit: WeeklyLimit, records: [WeeklyLimitRecord], now: Date, calendar: Calendar) {
        guard let resetsAt = limit.resetsAt else {
            return nil
        }
        let week = Week(endingAt: resetsAt)
        // Unchanged readings aren't always stored, so add the latest one at now.
        let points =
            UsagePoint.points(from: records, limitID: limit.limitID, in: week, until: now)
            + [UsagePoint(time: now, usedPercent: limit.usedPercent)]
        let days = DayUsage.days(of: points, in: week, until: now, calendar: calendar)

        self.init(
            percentLeft: limit.percentLeft,
            week: week,
            runs: ChartPoint.runs(of: points, in: week),
            days: days,
            dayGroups: DayGroup.groups(
                of: days, haveReadings: DayUsage.haveReadings(days, points: points, in: week)),
            todayIndex: DayUsage.todayIndex(of: days),
            versusEvenPace: Pace.versusEvenPace(percentLeft: limit.percentLeft, in: week, at: now),
            runsOutAt: Pace.runsOutAt(usedPercent: limit.usedPercent, in: week, at: now),
            projectionEnd: Pace.projectionEnd(usedPercent: limit.usedPercent, in: week, at: now))
    }
}
