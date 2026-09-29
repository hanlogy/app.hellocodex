import CodexClient

/// What the weekly limit needs from Codex. `CodexClient` provides it; tests
/// use a fake.
public protocol CodexReading: Sendable {
    var events: AsyncStream<CodexClient.Event> { get }
    func readRateLimits() async throws -> RateLimits
    func readAccount() async throws -> Account?
}

extension CodexClient: CodexReading {}
