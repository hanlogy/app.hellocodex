import CodexClient
import Foundation
import Testing

@testable import WeeklyLimit

private let week = 7 * 24 * 60

private func window(minutes: Int, used: Double = 10) -> RateLimitWindow {
    RateLimitWindow(usedPercent: used, windowDurationMins: minutes, resetsAt: 1_700_000_000)
}

private func rateLimits(
    main: RateLimitBucket? = nil, byLimitID: [String: RateLimitBucket]? = nil
) -> RateLimits {
    RateLimits(accountId: nil, rateLimits: main, rateLimitsByLimitId: byLimitID)
}

struct WeeklyLimitRateLimitsTests {
    @Test func picksTheSevenDayWindowFromTheMainBucket() {
        let limits = rateLimits(
            main: RateLimitBucket(
                limitId: "codex", primary: window(minutes: 300),
                secondary: window(minutes: week, used: 42)))

        #expect(
            WeeklyLimit(rateLimits: limits)
                == WeeklyLimit(
                    limitID: "codex", usedPercent: 42,
                    resetsAt: Date(timeIntervalSince1970: 1_700_000_000)))
    }

    @Test func usesCodexWhenTheMainBucketHasNoLimitID() {
        let limits = rateLimits(
            main: RateLimitBucket(limitId: nil, primary: window(minutes: week), secondary: nil))

        #expect(WeeklyLimit(rateLimits: limits)?.limitID == "codex")
    }

    @Test func fallsBackToTheBucketsByLimitID() {
        let limits = rateLimits(
            main: RateLimitBucket(limitId: "codex", primary: window(minutes: 300), secondary: nil),
            byLimitID: [
                "other": RateLimitBucket(
                    limitId: nil, primary: nil, secondary: window(minutes: week))
            ])

        #expect(WeeklyLimit(rateLimits: limits)?.limitID == "other")
    }

    @Test func picksTheSameBucketEveryTimeWhenSeveralHaveOne() {
        let buckets = Dictionary(
            uniqueKeysWithValues: ["zeta", "alpha", "mid"].map {
                ($0, RateLimitBucket(limitId: nil, primary: window(minutes: week), secondary: nil))
            })

        #expect(WeeklyLimit(rateLimits: rateLimits(byLimitID: buckets))?.limitID == "alpha")
    }

    @Test func isNilWithoutASevenDayWindow() {
        let limits = rateLimits(
            main: RateLimitBucket(limitId: "codex", primary: window(minutes: 300), secondary: nil))

        #expect(WeeklyLimit(rateLimits: limits) == nil)
    }

    @Test func keepsAMissingResetTimeMissing() {
        let limits = rateLimits(
            main: RateLimitBucket(
                limitId: "codex",
                primary: RateLimitWindow(usedPercent: 5, windowDurationMins: week, resetsAt: nil),
                secondary: nil))

        #expect(WeeklyLimit(rateLimits: limits)?.resetsAt == nil)
    }

    @Test func showsWhatIsLeft() {
        #expect(WeeklyLimit(limitID: "codex", usedPercent: 21, resetsAt: nil).percentLeft == 79)
    }
}
