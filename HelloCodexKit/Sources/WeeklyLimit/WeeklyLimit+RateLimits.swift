import CodexClient
import Foundation

extension WeeklyLimit {
    private static let weekInMinutes = 7 * 24 * 60

    /// The 7-day window in Codex's rate limits: from the main bucket first,
    /// then from the buckets by limit ID, in order of their ID so the choice is
    /// always the same. nil when there's no 7-day window.
    init?(rateLimits: RateLimits) {
        if let bucket = rateLimits.rateLimits, let limit = Self(bucket: bucket, limitID: "codex") {
            self = limit
            return
        }
        let buckets = (rateLimits.rateLimitsByLimitId ?? [:]).sorted { $0.key < $1.key }
        for (limitID, bucket) in buckets {
            if let limit = Self(bucket: bucket, limitID: limitID) {
                self = limit
                return
            }
        }
        return nil
    }

    /// The bucket's 7-day window; its own limit ID wins over `limitID`.
    private init?(bucket: RateLimitBucket, limitID: String) {
        let window = [bucket.primary, bucket.secondary].compactMap { $0 }
            .first { $0.windowDurationMins == Self.weekInMinutes }
        guard let window else {
            return nil
        }
        self.init(
            limitID: bucket.limitId ?? limitID,
            usedPercent: window.usedPercent,
            resetsAt: window.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) })
    }
}
