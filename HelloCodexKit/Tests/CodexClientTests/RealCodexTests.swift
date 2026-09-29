import Foundation
import Testing

@testable import CodexClient

/// Talks to the Codex installed on this Mac. Run with
/// `HELLOCODEX_REAL_CODEX=1 swift test`; it's skipped otherwise, because CI has
/// no Codex.
@Suite(
    .enabled(if: ProcessInfo.processInfo.environment["HELLOCODEX_REAL_CODEX"] == "1"),
    .timeLimit(.minutes(1)))
struct RealCodexTests {
    @Test func readsTheRateLimitsAndAccountFromTheInstalledCodex() async throws {
        let client = CodexClient(
            clientInfo: ClientInfo(
                name: "hellocodex-tests", title: "Hello Codex tests", version: "1.0"))
        var events = client.events.makeAsyncIterator()
        await client.start()

        #expect(await events.next() == .connected)
        let rateLimits = try await client.readRateLimits()
        let account = try await client.readAccount()
        await client.stop()

        #expect(rateLimits.rateLimits != nil || rateLimits.rateLimitsByLimitId != nil)
        #expect(account != nil)
    }
}
