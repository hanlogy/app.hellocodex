import Foundation

/// The 7 days a weekly limit covers, ending when it resets.
public struct Week: Equatable, Sendable {
    public let startsAt: Date
    public let resetsAt: Date

    static let length: TimeInterval = 7 * 24 * 60 * 60

    public init(endingAt resetsAt: Date) {
        self.startsAt = resetsAt.addingTimeInterval(-Self.length)
        self.resetsAt = resetsAt
    }

    /// How far through the week `time` is, from 0 at the start to 1 at the
    /// reset.
    func elapsedFraction(at time: Date) -> Double {
        time.timeIntervalSince(startsAt) / resetsAt.timeIntervalSince(startsAt)
    }

    /// The start of each calendar day overlapping the week: the week start,
    /// then every midnight before the reset. Days can be 23 or 25 hours long
    /// when the clocks change.
    func dayStarts(in calendar: Calendar) -> [Date] {
        var starts = [startsAt]
        var day = calendar.startOfDay(for: startsAt)
        while let next = calendar.date(byAdding: .day, value: 1, to: day), next < resetsAt {
            starts.append(next)
            day = next
        }
        return starts
    }
}
