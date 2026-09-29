import Foundation
import Testing

@testable import CodexClient

@Suite(.timeLimit(.minutes(1)))
struct AppServerConnectionTests {
    @Test func releasesTheConnectionOnceItsRequestsAreAnsweredAndItIsClosed() async throws {
        var connection: AppServerConnection? = try AppServerConnection.launch(
            executable: try FakeCodex.make(.working), requestTimeout: .seconds(10))
        _ = try await connection?.request(method: "initialize", params: NoParams())
        await connection?.close()

        weak let released = connection
        connection = nil
        // The process takes a moment to exit, which ends the reading task.
        for _ in 0..<20 where released != nil {
            try await Task.sleep(for: .milliseconds(100))
        }

        #expect(released == nil)
    }
}
