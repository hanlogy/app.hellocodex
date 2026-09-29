import Foundation
import Testing

@testable import CodexClient

struct CodexExecutableTests {
    @Test func findsExecutableCodexOnPathOnceEachInOrder() throws {
        let first = try FakeCodex.make(.working).deletingLastPathComponent()
        let second = try FakeCodex.make(.working).deletingLastPathComponent()
        let notExecutable = FileManager.default.temporaryDirectory
            .appending(path: "hellocodex-plain-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: notExecutable, withIntermediateDirectories: true)
        try Data().write(to: notExecutable.appending(path: "codex"))
        let path = [second, notExecutable, first, second].map { $0.path(percentEncoded: false) }
            .joined(separator: ":")

        let candidates = CodexExecutable.candidates(environment: ["PATH": path])
            .filter { !CodexExecutable.knownLocations.contains($0.path(percentEncoded: false)) }

        #expect(candidates.map(\.lastPathComponent) == ["codex", "codex"])
        #expect(
            candidates.map { $0.deletingLastPathComponent().path(percentEncoded: false) }
                == [second, first].map { $0.path(percentEncoded: false) })
    }

    @Test func alsoLooksWhereHomebrewAndTheChatGPTAppInstallCodex() {
        let candidates = CodexExecutable.candidates(environment: [:]).map {
            $0.path(percentEncoded: false)
        }

        #expect(candidates.allSatisfy(CodexExecutable.knownLocations.contains))
    }
}
