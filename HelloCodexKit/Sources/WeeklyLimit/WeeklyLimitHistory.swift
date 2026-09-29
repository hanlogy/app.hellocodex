import Foundation
import Storage

/// The stored readings of one account's weekly limit.
struct WeeklyLimitHistory: Sendable {
    /// Unchanged readings are kept this far apart. Those samples show that
    /// recording continued; a longer gap shows it stopped.
    private static let unchangedSampleInterval: TimeInterval = 5 * 60

    private let store: MonthlyRecordStore<WeeklyLimitRecord>

    init(accountDirectory: URL) {
        store = MonthlyRecordStore(directory: accountDirectory, filePrefix: "weekly-limit")
    }

    /// Stores a change at once, and an unchanged reading only when the last
    /// one is at least five minutes old.
    func record(_ limit: WeeklyLimit, at recordedAt: Date) throws {
        let record = WeeklyLimitRecord(limit: limit, recordedAt: recordedAt)
        let recent = try store.records(
            from: recordedAt.addingTimeInterval(-Self.unchangedSampleInterval), to: recordedAt)
        if let last = recent.last, last.hasSameReading(as: record),
            recordedAt.timeIntervalSince(last.recordedAt) < Self.unchangedSampleInterval
        {
            return
        }
        try store.append(record)
    }

    /// The readings from `start` to `end`, both included, oldest first.
    func records(from start: Date, to end: Date) throws -> [WeeklyLimitRecord] {
        try store.records(from: start, to: end)
    }
}
