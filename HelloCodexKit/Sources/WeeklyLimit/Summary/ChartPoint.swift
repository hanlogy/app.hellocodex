import Foundation

/// A point on the chart: how much of the limit was left at a time.
public struct ChartPoint: Equatable, Sendable {
    public let time: Date
    /// 0–100.
    public let percentLeft: Double

    public init(time: Date, percentLeft: Double) {
        self.time = time
        self.percentLeft = percentLeft
    }
}

extension ChartPoint {
    /// While the app runs, readings are at most about 10 minutes apart:
    /// unchanged readings are kept 5 minutes apart and read every 5 minutes.
    /// A longer pause means the app wasn't running.
    static let gap: TimeInterval = 15 * 60

    /// Splits the week's readings into runs where the app was running. The
    /// week starts at 100% left, so that point begins the first run.
    static func runs(of points: [UsagePoint], in week: Week) -> [[ChartPoint]] {
        var runs: [[ChartPoint]] = []
        for point in [UsagePoint(time: week.startsAt, usedPercent: 0)] + points {
            let chartPoint = ChartPoint(time: point.time, percentLeft: 100 - point.usedPercent)
            if let previous = runs.last?.last, point.time.timeIntervalSince(previous.time) <= gap {
                runs[runs.count - 1].append(chartPoint)
            } else {
                runs.append([chartPoint])
            }
        }
        return runs
    }
}
