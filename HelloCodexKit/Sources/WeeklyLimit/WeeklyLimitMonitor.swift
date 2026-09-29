import CodexClient
import Foundation
import Observation
import Storage

/// Keeps the weekly limit and the week's summary up to date: reads the limit
/// from Codex whenever it connects, when the limits or the account change, and
/// every few minutes; records each reading for the signed-in account; and
/// summarizes that account's week.
@MainActor
@Observable
public final class WeeklyLimitMonitor {
    /// The latest reading, or nil before the first one or without a weekly
    /// limit.
    public private(set) var limit: WeeklyLimit?
    /// The signed-in account's week, or nil without a reset time.
    public private(set) var summary: WeeklySummary?

    /// Notifications after which the limit is read again: the limits changed,
    /// or another account signed in.
    private static let refreshingNotifications: Set<String> = [
        "account/rateLimits/updated", "account/updated",
    ]

    private let codex: any CodexReading
    private let dataDirectory: DataDirectory
    private let refreshInterval: Duration
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private var isRunning = false
    private var eventTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var isReading = false
    private var needsAnotherRead = false

    /// - Parameter refreshInterval: Notifications can miss changes made
    ///   elsewhere, such as on another machine, so the limit is also read this
    ///   often.
    public init(
        codex: any CodexReading,
        dataDirectory: DataDirectory,
        refreshInterval: Duration = .seconds(5 * 60),
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.codex = codex
        self.dataDirectory = dataDirectory
        self.refreshInterval = refreshInterval
        self.calendar = calendar
        self.now = now
    }

    /// Starts listening to Codex and reading every few minutes.
    public func start() {
        guard !isRunning else {
            return
        }
        isRunning = true
        listenToCodex()
        timerTask = Task { [weak self, refreshInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: refreshInterval)
                guard let self, !Task.isCancelled else {
                    return
                }
                self.requestRefresh()
            }
        }
    }

    /// Stops reacting to Codex and reading every few minutes, until
    /// ``start()``.
    public func stop() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    /// Listens for as long as the monitor exists. Cancelling a loop over
    /// Codex's events would end the event stream for good, so stop() only
    /// makes the loop ignore them.
    private func listenToCodex() {
        guard eventTask == nil else {
            return
        }
        eventTask = Task { [weak self, codex] in
            for await event in codex.events {
                guard let self else {
                    return
                }
                if self.isRunning && self.shouldRead(after: event) {
                    self.requestRefresh()
                }
            }
        }
    }

    private func shouldRead(after event: CodexClient.Event) -> Bool {
        switch event {
        case .connected:
            true
        case .notification(let method):
            Self.refreshingNotifications.contains(method)
        }
    }

    /// Reads, records, and summarizes, without waiting for it. Requests
    /// during a read are combined into one more read after it, so reads never
    /// overlap and none is lost.
    private func requestRefresh() {
        guard !isReading else {
            needsAnotherRead = true
            return
        }
        isReading = true
        Task {
            repeat {
                needsAnotherRead = false
                await read()
            } while needsAnotherRead
            isReading = false
        }
    }

    private func read() async {
        guard let rateLimits = try? await codex.readRateLimits() else {
            // Keep showing the last reading until Codex answers again.
            return
        }
        let limit = WeeklyLimit(rateLimits: rateLimits)
        let time = now()
        let history = await accountHistory(accountID: rateLimits.accountId)
        if let limit, let history {
            try? history.record(limit, at: time)
        }
        self.limit = limit
        summary = limit.flatMap { summarize($0, history: history, at: time) }
    }

    /// The signed-in account's readings, or nil when Codex doesn't say who
    /// that is. The email is only asked for when the ID is missing.
    private func accountHistory(accountID: String?) async -> WeeklyLimitHistory? {
        var key = AccountFolderKey(accountID: accountID, email: nil)
        if key == nil, let account = try? await codex.readAccount() {
            key = AccountFolderKey(accountID: nil, email: account.email)
        }
        return key.map {
            WeeklyLimitHistory(accountDirectory: dataDirectory.accountDirectory(for: $0))
        }
    }

    /// Without an account there's no history, so the week has only the
    /// latest reading.
    private func summarize(_ limit: WeeklyLimit, history: WeeklyLimitHistory?, at time: Date)
        -> WeeklySummary?
    {
        guard let resetsAt = limit.resetsAt else {
            return nil
        }
        let week = Week(endingAt: resetsAt)
        let records = (try? history?.records(from: min(week.startsAt, time), to: time)) ?? []
        return WeeklySummary(limit: limit, records: records, now: time, calendar: calendar)
    }
}
