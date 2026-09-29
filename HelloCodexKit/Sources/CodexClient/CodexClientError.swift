/// Why a request to Codex failed.
public enum CodexClientError: Error, Equatable, Sendable {
    /// No copy of Codex is connected right now.
    case notConnected
    /// None of the Codex executables completed the handshake.
    case noWorkingCodex
    /// Codex didn't answer within the request timeout.
    case timedOut(method: String)
    /// The connection closed before Codex answered.
    case disconnected
    /// Codex answered with an error.
    case server(message: String)
}
