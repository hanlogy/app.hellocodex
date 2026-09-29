import Foundation

/// A read-only connection to Codex through `codex app-server`.
///
/// After ``start()``, it keeps a connection open: it uses the first Codex
/// executable that completes the handshake and reconnects with a growing delay
/// whenever the connection is lost, until ``stop()``. Only typed reads are
/// public, so Hello Codex can't send Codex commands.
public actor CodexClient {
    public enum Event: Equatable, Sendable {
        /// A connection is ready, the first one or after a reconnect.
        case connected
        /// Codex sent a notification with this method.
        case notification(method: String)
    }

    /// Timings, so tests can use short ones.
    public struct Timing: Sendable {
        public var requestTimeout: Duration
        public var minimumRetryDelay: Duration
        public var maximumRetryDelay: Duration

        public init(
            requestTimeout: Duration, minimumRetryDelay: Duration, maximumRetryDelay: Duration
        ) {
            self.requestTimeout = requestTimeout
            self.minimumRetryDelay = minimumRetryDelay
            self.maximumRetryDelay = maximumRetryDelay
        }

        public static let standard = Timing(
            requestTimeout: .seconds(15), minimumRetryDelay: .seconds(1),
            maximumRetryDelay: .seconds(30))
    }

    /// Connections and notifications, for as long as the client runs.
    public nonisolated let events: AsyncStream<Event>

    private let clientInfo: ClientInfo
    private let executables: [URL]
    private let timing: Timing
    private let eventContinuation: AsyncStream<Event>.Continuation
    private var connection: AppServerConnection?
    /// The connection whose handshake is in progress, so stop() can close it.
    private var connecting: AppServerConnection?
    private var runTask: Task<Void, Never>?
    private var isStopped = false

    public init(
        clientInfo: ClientInfo,
        executables: [URL] = CodexExecutable.candidates(),
        timing: Timing = .standard
    ) {
        self.clientInfo = clientInfo
        self.executables = executables
        self.timing = timing
        (events, eventContinuation) = AsyncStream.makeStream()
    }

    /// Starts connecting, and keeps reconnecting until ``stop()``.
    public func start() {
        guard runTask == nil, !isStopped else {
            return
        }
        runTask = Task { await self.run() }
    }

    /// Closes the connection and stops reconnecting. A stopped client can't be
    /// started again.
    public func stop() async {
        isStopped = true
        runTask?.cancel()
        runTask = nil
        await connecting?.close()
        await connection?.close()
        connection = nil
        eventContinuation.finish()
    }

    /// Codex's current rate limits, with the account they belong to.
    public func readRateLimits() async throws -> RateLimits {
        try await request(CodexMethod.readRateLimits, as: RateLimits.self)
    }

    /// The signed-in account, or nil when nobody is signed in.
    public func readAccount() async throws -> Account? {
        try await request(CodexMethod.readAccount, as: AccountResponse.self).account
    }

    private func request<Result: Decodable>(_ method: String, as type: Result.Type) async throws
        -> Result
    {
        guard let connection else {
            throw CodexClientError.notConnected
        }
        let reply = try await connection.request(method: method, params: NoParams())
        return try JSONDecoder().decode(JSONRPCReply<Result>.self, from: reply).result
    }

    /// Connects, stays connected until the connection closes, then waits and
    /// connects again. Failed attempts double the wait, up to the maximum.
    private func run() async {
        var retryDelay = timing.minimumRetryDelay
        while !Task.isCancelled {
            guard let connected = await connectToAny() else {
                try? await Task.sleep(for: retryDelay)
                retryDelay = min(retryDelay * 2, timing.maximumRetryDelay)
                continue
            }
            // stop() may have come while this connection was being set up.
            guard !Task.isCancelled else {
                await connected.close()
                return
            }
            connection = connected
            eventContinuation.yield(.connected)
            await forwardNotifications(of: connected)
            connection = nil
            retryDelay = timing.minimumRetryDelay
            try? await Task.sleep(for: retryDelay)
        }
    }

    /// Codex may be installed in several places, and some copies can be
    /// broken, so use the first one that completes the handshake.
    private func connectToAny() async -> AppServerConnection? {
        for executable in executables where !Task.isCancelled {
            guard
                let candidate = try? AppServerConnection.launch(
                    executable: executable, requestTimeout: timing.requestTimeout)
            else {
                continue
            }
            connecting = candidate
            defer { connecting = nil }
            do {
                _ = try await candidate.request(
                    method: CodexMethod.initialize, params: InitializeParams(clientInfo: clientInfo)
                )
                try await candidate.notify(method: CodexMethod.initialized, params: NoParams())
                return candidate
            } catch {
                await candidate.close()
            }
        }
        return nil
    }

    /// Passes the connection's notifications on until it closes.
    private func forwardNotifications(of connection: AppServerConnection) async {
        for await method in connection.notifications {
            eventContinuation.yield(.notification(method: method))
        }
    }
}
