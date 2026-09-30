import CodexClient
import Foundation
import Storage
import Testing

@testable import WeeklyLimit

private let accountID = "123e4567-e89b-12d3-a456-426614174000"
private let now = local(2026, 9, 29, 12)
private let resetsAt = local(2026, 10, 2, 9)

private func rateLimits(used: Double = 21, accountID: String? = accountID, weekly: Bool = true)
    -> RateLimits
{
    let window = RateLimitWindow(
        usedPercent: used, windowDurationMins: weekly ? 7 * 24 * 60 : 300,
        resetsAt: Int(resetsAt.timeIntervalSince1970))
    return RateLimits(
        accountId: accountID,
        rateLimits: RateLimitBucket(limitId: "codex", primary: window, secondary: nil),
        rateLimitsByLimitId: nil)
}

/// Waits until `condition` holds, for up to five seconds.
@MainActor
private func eventually(_ condition: () async -> Bool) async throws {
    for _ in 0..<100 where !(await condition()) {
        try await Task.sleep(for: .milliseconds(50))
    }
}

/// A started monitor with its data folder in a new temporary folder, removed
/// after the test.
@MainActor
private func withMonitor(
    _ codex: FakeCodexReading,
    refreshInterval: Duration = .seconds(60),
    _ body: (WeeklyLimitMonitor, URL) async throws -> Void
) async throws {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "hellocodex-monitor-\(UUID().uuidString)", directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let monitor = WeeklyLimitMonitor(
        codex: codex, dataDirectory: DataDirectory(url: directory),
        refreshInterval: refreshInterval,
        calendar: stockholm, now: { now })
    monitor.start()
    defer { monitor.stop() }
    try await body(monitor, directory)
}

private func readingsFile(in directory: URL, account: String) -> URL {
    directory.appending(path: "accounts/\(account)/weekly-limit-2026-09.jsonl")
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct WeeklyLimitMonitorTests {
    @Test func readsRecordsAndSummarizesWhenCodexConnects() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits(used: 21))
        try await withMonitor(codex) { monitor, directory in
            codex.send(.connected)
            try await eventually { monitor.summary != nil }

            #expect(
                monitor.limit == WeeklyLimit(limitID: "codex", usedPercent: 21, resetsAt: resetsAt))
            #expect(monitor.summary?.percentLeft == 79)
            #expect(monitor.status == .summarized)
            #expect(
                FileManager.default.fileExists(
                    atPath: readingsFile(in: directory, account: accountID).path(
                        percentEncoded: false)))
        }
    }

    @Test func readsAgainWhenTheLimitsOrTheAccountChange() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits())
        try await withMonitor(codex) { _, _ in
            codex.send(.connected)
            try await eventually { await codex.rateLimitReads == 1 }

            codex.send(.notification(method: "account/rateLimits/updated"))
            try await eventually { await codex.rateLimitReads == 2 }
            codex.send(.notification(method: "account/updated"))
            try await eventually { await codex.rateLimitReads == 3 }
            codex.send(.notification(method: "thread/started"))
            try await Task.sleep(for: .milliseconds(200))

            #expect(await codex.rateLimitReads == 3)
        }
    }

    @Test func readsAgainEveryRefreshInterval() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits())
        try await withMonitor(codex, refreshInterval: .milliseconds(100)) { _, _ in
            try await eventually { await codex.rateLimitReads >= 2 }

            #expect(await codex.rateLimitReads >= 2)
        }
    }

    @Test func recordsUnderTheEmailWhenCodexDoesNotSendTheAccountID() async throws {
        let codex = FakeCodexReading(
            rateLimits: rateLimits(accountID: nil),
            account: Account(type: "chatgpt", email: "me@example.com"))
        try await withMonitor(codex) { monitor, directory in
            codex.send(.connected)
            try await eventually { monitor.summary != nil }

            let key = try #require(AccountFolderKey(accountID: nil, email: "me@example.com"))
            #expect(
                FileManager.default.fileExists(
                    atPath: readingsFile(in: directory, account: key.rawValue).path(
                        percentEncoded: false)))
        }
    }

    @Test func showsTheLimitButRecordsNothingWithoutAnAccount() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits(accountID: nil), account: nil)
        try await withMonitor(codex) { monitor, directory in
            codex.send(.connected)
            try await eventually { monitor.summary != nil }

            #expect(monitor.limit?.usedPercent == 21)
            #expect(!FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)))
        }
    }

    @Test func isLoadingUntilCodexAnswers() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits())
        try await withMonitor(codex) { monitor, _ in
            #expect(monitor.status == .loading)
        }
    }

    @Test func failsWhenCodexCannotBeReadAndRecoversWhenItCan() async throws {
        let codex = FakeCodexReading(rateLimits: nil)
        try await withMonitor(codex) { monitor, _ in
            codex.send(.connected)
            try await eventually { monitor.status != .loading }
            #expect(monitor.status == .failed)

            await codex.answer(rateLimits())
            codex.send(.connected)
            try await eventually { monitor.status != .failed }
            #expect(monitor.status == .summarized)
        }
    }

    @Test func keepsTheLastReadingWhenCodexStopsAnswering() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits(used: 21))
        try await withMonitor(codex) { monitor, _ in
            codex.send(.connected)
            try await eventually { monitor.limit != nil }

            await codex.answer(nil)
            codex.send(.connected)
            try await eventually { await codex.rateLimitReads == 2 }
            try await Task.sleep(for: .milliseconds(100))

            #expect(monitor.limit?.usedPercent == 21)
            #expect(monitor.status == .summarized)
        }
    }

    @Test func showsNoLimitWithoutASevenDayWindow() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits(weekly: false))
        try await withMonitor(codex) { monitor, _ in
            codex.send(.connected)
            try await eventually { await codex.rateLimitReads == 1 }
            try await Task.sleep(for: .milliseconds(100))

            #expect(monitor.limit == nil)
            #expect(monitor.summary == nil)
            #expect(monitor.status == .noWeeklyLimit)
        }
    }

    @Test func neverReadsTwiceAtOnceAndLosesNoRefresh() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits(), readDelay: .milliseconds(300))
        try await withMonitor(codex) { _, _ in
            codex.send(.connected)
            try await eventually { await codex.rateLimitReads == 1 }
            codex.send(.notification(method: "account/rateLimits/updated"))
            codex.send(.notification(method: "account/updated"))
            try await eventually { await codex.rateLimitReads == 2 }
            try await Task.sleep(for: .milliseconds(700))

            #expect(await codex.mostReadsAtOnce == 1)
            #expect(await codex.rateLimitReads == 2)
        }
    }

    @Test func stopsReadingWhenStopped() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits())
        try await withMonitor(codex) { monitor, _ in
            codex.send(.connected)
            try await eventually { await codex.rateLimitReads == 1 }

            monitor.stop()
            codex.send(.connected)
            try await Task.sleep(for: .milliseconds(200))

            #expect(await codex.rateLimitReads == 1)
        }
    }

    @Test func readsAgainWhenStartedAfterBeingStopped() async throws {
        let codex = FakeCodexReading(rateLimits: rateLimits())
        try await withMonitor(codex) { monitor, _ in
            codex.send(.connected)
            try await eventually { await codex.rateLimitReads == 1 }

            monitor.stop()
            monitor.start()
            codex.send(.connected)
            try await eventually { await codex.rateLimitReads == 2 }

            #expect(await codex.rateLimitReads == 2)
        }
    }
}
