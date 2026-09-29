/// Codex's rate limits, from `account/rateLimits/read`.
public struct RateLimits: Decodable, Equatable, Sendable {
    /// The account the limits belong to, when the backend supplies it.
    public let accountId: String?
    public let rateLimits: RateLimitBucket?
    public let rateLimitsByLimitId: [String: RateLimitBucket]?

    public init(
        accountId: String?,
        rateLimits: RateLimitBucket?,
        rateLimitsByLimitId: [String: RateLimitBucket]?
    ) {
        self.accountId = accountId
        self.rateLimits = rateLimits
        self.rateLimitsByLimitId = rateLimitsByLimitId
    }
}

/// One limit, with up to two windows of different lengths.
public struct RateLimitBucket: Decodable, Equatable, Sendable {
    public let limitId: String?
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?

    public init(limitId: String?, primary: RateLimitWindow?, secondary: RateLimitWindow?) {
        self.limitId = limitId
        self.primary = primary
        self.secondary = secondary
    }
}

/// How much of a limit is used in one window, and when the window resets.
public struct RateLimitWindow: Decodable, Equatable, Sendable {
    public let usedPercent: Double
    public let windowDurationMins: Int?
    /// Unix time in seconds.
    public let resetsAt: Int?

    public init(usedPercent: Double, windowDurationMins: Int?, resetsAt: Int?) {
        self.usedPercent = usedPercent
        self.windowDurationMins = windowDurationMins
        self.resetsAt = resetsAt
    }
}
