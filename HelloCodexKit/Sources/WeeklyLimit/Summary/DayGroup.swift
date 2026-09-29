/// A bar in "Used per day": one day, or several when the app didn't record on
/// the earlier ones, so their usage can't be split between them.
public struct DayGroup: Equatable, Sendable {
    /// Indexes in ``WeeklySummary/days``, both included.
    public let firstDay: Int
    public let lastDay: Int
    /// nil for a day that hasn't started yet.
    public let usedPercent: Double?

    public init(firstDay: Int, lastDay: Int, usedPercent: Double?) {
        self.firstDay = firstDay
        self.lastDay = lastDay
        self.usedPercent = usedPercent
    }
}

extension DayGroup {
    /// Merges each run of started days without readings into the next day with
    /// readings, since their usage was only seen then. Later days stay single.
    static func groups(of days: [DayUsage], haveReadings: [Bool]) -> [DayGroup] {
        var groups: [DayGroup] = []
        var firstDay = 0
        var usedPercent = 0.0
        for (index, day) in days.enumerated() {
            guard let used = day.usedPercent else {
                groups.append(DayGroup(firstDay: index, lastDay: index, usedPercent: nil))
                firstDay = index + 1
                continue
            }
            usedPercent += used
            // Today always has the latest reading, so every run ends by today.
            let nextHasStarted = index + 1 < days.count && days[index + 1].usedPercent != nil
            if haveReadings[index] || !nextHasStarted {
                groups.append(
                    DayGroup(firstDay: firstDay, lastDay: index, usedPercent: usedPercent))
                firstDay = index + 1
                usedPercent = 0
            }
        }
        return groups
    }
}
