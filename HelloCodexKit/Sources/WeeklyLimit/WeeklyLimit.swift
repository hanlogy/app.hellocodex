import Foundation

/// How much of Codex's weekly limit is used, and when it resets.
public struct WeeklyLimit: Equatable, Sendable {
    let limitID: String
    /// 0–100.
    let usedPercent: Double
    /// nil when Codex doesn't say.
    let resetsAt: Date?

    init(limitID: String, usedPercent: Double, resetsAt: Date?) {
        self.limitID = limitID
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
    }

    /// 0–100; Codex reports what's used, the app shows what's left.
    public var percentLeft: Double {
        100 - usedPercent
    }
}
