import CodexClient
import Foundation

@testable import WeeklyLimit

/// A Codex that answers what the test sets, and counts what it's asked.
actor FakeCodexReading: CodexReading {
    struct Unavailable: Error {}

    nonisolated let events: AsyncStream<CodexClient.Event>
    private nonisolated let continuation: AsyncStream<CodexClient.Event>.Continuation

    /// nil makes reads fail.
    private var rateLimits: RateLimits?
    private var account: Account?
    private var readDelay: Duration?
    private var readsInProgress = 0
    private(set) var rateLimitReads = 0
    private(set) var accountReads = 0
    private(set) var mostReadsAtOnce = 0

    init(rateLimits: RateLimits?, account: Account? = nil, readDelay: Duration? = nil) {
        (events, continuation) = AsyncStream.makeStream()
        self.rateLimits = rateLimits
        self.account = account
        self.readDelay = readDelay
    }

    nonisolated func send(_ event: CodexClient.Event) {
        continuation.yield(event)
    }

    func answer(_ rateLimits: RateLimits?) {
        self.rateLimits = rateLimits
    }

    func readRateLimits() async throws -> RateLimits {
        rateLimitReads += 1
        readsInProgress += 1
        mostReadsAtOnce = max(mostReadsAtOnce, readsInProgress)
        defer { readsInProgress -= 1 }
        if let readDelay {
            try await Task.sleep(for: readDelay)
        }
        guard let rateLimits else {
            throw Unavailable()
        }
        return rateLimits
    }

    func readAccount() async throws -> Account? {
        accountReads += 1
        return account
    }
}
