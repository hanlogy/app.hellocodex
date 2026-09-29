import Foundation
import Testing

@testable import CodexClient

private let clientInfo = ClientInfo(
    name: "hellocodex-tests", title: "Hello Codex tests", version: "1.0")

// Fast retries, but a request timeout generous enough for the fake to start
// while the tests run in parallel.
private let testTiming = CodexClient.Timing(
    requestTimeout: .seconds(5), minimumRetryDelay: .milliseconds(50),
    maximumRetryDelay: .milliseconds(200))

/// A started client for the given executables, stopped after the test.
private func withClient(
    _ executables: [URL],
    timing: CodexClient.Timing = testTiming,
    _ body: (CodexClient, inout AsyncStream<CodexClient.Event>.Iterator) async throws -> Void
) async throws {
    let client = CodexClient(clientInfo: clientInfo, executables: executables, timing: timing)
    var events = client.events.makeAsyncIterator()
    await client.start()
    do {
        try await body(client, &events)
    } catch {
        await client.stop()
        throw error
    }
    await client.stop()
}

@Suite(.timeLimit(.minutes(1)))
struct CodexClientTests {
    @Test func readsTheRateLimitsAfterConnecting() async throws {
        try await withClient([try FakeCodex.make(.working)]) { client, events in
            #expect(await events.next() == .connected)

            let rateLimits = try await client.readRateLimits()

            #expect(rateLimits.accountId == FakeCodex.accountID)
            #expect(
                rateLimits.rateLimits?.secondary
                    == RateLimitWindow(
                        usedPercent: 21, windowDurationMins: 10080, resetsAt: 1_791_047_411))
        }
    }

    @Test func doesNotTreatARequestFromCodexAsTheReplyToOurs() async throws {
        // The fake sends its own request with our id before its reply.
        try await withClient([try FakeCodex.make(.working)]) { client, events in
            _ = await events.next()

            let rateLimits = try await client.readRateLimits()

            #expect(rateLimits.rateLimits?.limitId == "codex")
        }
    }

    @Test func passesOnCodexsNotifications() async throws {
        try await withClient([try FakeCodex.make(.working)]) { client, events in
            _ = await events.next()
            _ = try await client.readRateLimits()

            #expect(await events.next() == .notification(method: "account/rateLimits/updated"))
        }
    }

    @Test func readsTheSignedInAccount() async throws {
        try await withClient([try FakeCodex.make(.working)]) { client, events in
            _ = await events.next()

            let account = try await client.readAccount()

            #expect(account == Account(type: "chatgpt", email: "me@example.com"))
        }
    }

    @Test func usesTheFirstCodexThatCompletesTheHandshake() async throws {
        try await withClient([try FakeCodex.make(.broken), try FakeCodex.make(.working)]) {
            client, events in
            #expect(await events.next() == .connected)
            let rateLimits = try await client.readRateLimits()

            #expect(rateLimits.accountId == FakeCodex.accountID)
        }
    }

    @Test func failsARequestCodexDoesNotAnswer() async throws {
        var timing = testTiming
        timing.requestTimeout = .milliseconds(300)
        try await withClient([try FakeCodex.make(.silent)], timing: timing) { client, events in
            _ = await events.next()

            await #expect(throws: CodexClientError.timedOut(method: "account/rateLimits/read")) {
                try await client.readRateLimits()
            }
        }
    }

    @Test func reportsCodexsErrors() async throws {
        try await withClient([try FakeCodex.make(.failing)]) { client, events in
            _ = await events.next()

            await #expect(throws: CodexClientError.server(message: "Not signed in")) {
                try await client.readAccount()
            }
        }
    }

    @Test func reconnectsAfterCodexExits() async throws {
        try await withClient([try FakeCodex.make(.exitingOnRead)]) { client, events in
            #expect(await events.next() == .connected)

            await #expect(throws: CodexClientError.disconnected) {
                try await client.readRateLimits()
            }
            #expect(await events.next() == .connected)
        }
    }

    @Test func leavesNoCodexRunningWhenStoppedDuringTheHandshake() async throws {
        let executable = try FakeCodex.make(.slowHandshake)
        let client = CodexClient(
            clientInfo: clientInfo, executables: [executable], timing: testTiming)
        await client.start()
        try await Task.sleep(for: .milliseconds(200))

        await client.stop()
        // stop() closes the connection at once, but the process takes a
        // moment to exit.
        var isRunning = try FakeCodex.isRunning(executable)
        for _ in 0..<20 where isRunning {
            try await Task.sleep(for: .milliseconds(100))
            isRunning = try FakeCodex.isRunning(executable)
        }

        #expect(!isRunning)
    }

    @Test func failsRequestsBeforeItIsConnected() async throws {
        let client = CodexClient(clientInfo: clientInfo, executables: [], timing: testTiming)

        await #expect(throws: CodexClientError.notConnected) {
            try await client.readRateLimits()
        }
    }
}
