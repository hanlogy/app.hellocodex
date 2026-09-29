import Foundation

/// One running `codex app-server` process and the JSON-RPC traffic with it.
actor AppServerConnection {
    private let process: Process
    private let input: FileHandle
    private let requestTimeout: Duration
    private let decoder = JSONDecoder()
    private var nextID = 1
    private var pending: [Int: PendingRequest] = [:]
    private var isClosed = false
    private let notificationContinuation: AsyncStream<String>.Continuation

    /// A request waiting for its reply, and the timer that gives up on it.
    private struct PendingRequest {
        let continuation: CheckedContinuation<Data, any Error>
        let timeout: Task<Void, Never>
    }

    /// The methods of notifications Codex sends. It ends when the connection
    /// closes.
    nonisolated let notifications: AsyncStream<String>

    private init(process: Process, input: FileHandle, requestTimeout: Duration) {
        self.process = process
        self.input = input
        self.requestTimeout = requestTimeout
        (notifications, notificationContinuation) = AsyncStream.makeStream()
    }

    /// Starts `executable app-server` and reads its output until it exits.
    static func launch(executable: URL, requestTimeout: Duration) throws -> AppServerConnection {
        let process = Process()
        process.executableURL = executable
        process.arguments = ["app-server"]
        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        // Writing to a process that has exited would otherwise raise SIGPIPE
        // and end the whole app; this makes the write throw instead.
        _ = fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1)
        try process.run()

        let connection = AppServerConnection(
            process: process, input: input.fileHandleForWriting, requestTimeout: requestTimeout)
        let reader = output.fileHandleForReading
        Task {
            do {
                for try await line in reader.bytes.lines {
                    await connection.handle(line: line)
                }
            } catch {}
            await connection.close()
        }
        return connection
    }

    /// Sends a request and waits for Codex's reply line.
    func request(method: String, params: some Encodable & Sendable) async throws -> Data {
        guard !isClosed else {
            throw CodexClientError.disconnected
        }
        let id = nextID
        nextID += 1
        let line = try JSONRPCWriter.line(JSONRPCRequest(id: id, method: method, params: params))

        return try await withCheckedThrowingContinuation { continuation in
            let timeout = Task { [requestTimeout] in
                guard (try? await Task.sleep(for: requestTimeout)) != nil else {
                    return
                }
                self.finish(id: id, with: .failure(CodexClientError.timedOut(method: method)))
            }
            pending[id] = PendingRequest(continuation: continuation, timeout: timeout)
            do {
                try input.write(contentsOf: line)
            } catch {
                finish(id: id, with: .failure(CodexClientError.disconnected))
            }
        }
    }

    /// Sends a notification, which Codex doesn't answer.
    func notify(method: String, params: some Encodable & Sendable) throws {
        guard !isClosed else {
            throw CodexClientError.disconnected
        }
        try input.write(
            contentsOf: JSONRPCWriter.line(JSONRPCNotification(method: method, params: params)))
    }

    /// Stops the process and fails the requests still waiting for a reply.
    func close() {
        guard !isClosed else {
            return
        }
        isClosed = true
        if process.isRunning {
            process.terminate()
        }
        for id in pending.keys {
            finish(id: id, with: .failure(CodexClientError.disconnected))
        }
        notificationContinuation.finish()
    }

    private func handle(line: String) {
        let data = Data(line.utf8)
        guard let message = try? decoder.decode(IncomingMessage.self, from: data) else {
            return
        }
        // Messages with a method are notifications or Codex's own requests,
        // never replies to ours.
        if let method = message.method {
            if message.id == nil {
                notificationContinuation.yield(method)
            }
            return
        }
        guard let id = message.id else {
            return
        }
        if let error = message.error {
            finish(id: id, with: .failure(CodexClientError.server(message: error.message)))
        } else {
            finish(id: id, with: .success(data))
        }
    }

    /// Answers a waiting request once, and stops its timer.
    private func finish(id: Int, with result: Result<Data, any Error>) {
        guard let request = pending.removeValue(forKey: id) else {
            return
        }
        request.timeout.cancel()
        request.continuation.resume(with: result)
    }
}
