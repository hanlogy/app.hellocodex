import Foundation
import Storage

/// One stored reading of the weekly limit, a line in
/// `weekly-limit-YYYY-MM.jsonl`.
struct WeeklyLimitRecord: TimestampedRecord {
    let recordedAt: Date
    let limitID: String
    let usedPercent: Double
    /// Unix time in seconds, as Codex reports it.
    let resetsAt: Int?

    private enum CodingKeys: String, CodingKey {
        case recordedAt
        case limitID = "limitId"
        case usedPercent
        case resetsAt
    }

    init(limit: WeeklyLimit, recordedAt: Date) {
        self.recordedAt = recordedAt
        limitID = limit.limitID
        usedPercent = limit.usedPercent
        resetsAt = limit.resetsAt.map { Int($0.timeIntervalSince1970) }
    }

    /// Whether both readings say the same about the limit.
    func hasSameReading(as other: WeeklyLimitRecord) -> Bool {
        limitID == other.limitID && usedPercent == other.usedPercent && resetsAt == other.resetsAt
    }
}
