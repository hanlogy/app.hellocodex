import Foundation

/// How the week's usage compares with an even pace, and where it's heading.
enum Pace {
    /// Points left above (+) or below (−) a straight line from 100% at the
    /// week start to 0% at the reset.
    static func versusEvenPace(percentLeft: Double, in week: Week, at now: Date) -> Double {
        percentLeft - 100 * (1 - week.elapsedFraction(at: now))
    }

    /// When the limit runs out at this week's average rate so far, or nil if
    /// it lasts until the reset.
    static func runsOutAt(usedPercent: Double, in week: Week, at now: Date) -> Date? {
        let rate = averageRate(usedPercent: usedPercent, in: week, at: now)
        guard rate > 0 else {
            return nil
        }
        let time = now.addingTimeInterval(max(0, 100 - usedPercent) / rate)
        return time < week.resetsAt ? time : nil
    }

    /// Where the projection line ends: when the limit runs out, or otherwise
    /// the percent left at the reset.
    static func projectionEnd(usedPercent: Double, in week: Week, at now: Date) -> ChartPoint {
        if let time = runsOutAt(usedPercent: usedPercent, in: week, at: now) {
            return ChartPoint(time: time, percentLeft: 0)
        }
        let rate = averageRate(usedPercent: usedPercent, in: week, at: now)
        let usedAtReset = usedPercent + rate * week.resetsAt.timeIntervalSince(now)
        return ChartPoint(time: week.resetsAt, percentLeft: 100 - usedAtReset)
    }

    /// Percent used per second, on average this week so far.
    private static func averageRate(usedPercent: Double, in week: Week, at now: Date) -> Double {
        let elapsed = now.timeIntervalSince(week.startsAt)
        return elapsed > 0 ? usedPercent / elapsed : 0
    }
}
