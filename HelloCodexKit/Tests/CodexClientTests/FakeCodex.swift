import Foundation

/// A fake `codex app-server`: a script that answers JSON-RPC lines the way the
/// real one does, with one behaviour per test.
enum FakeCodex {
    enum Behaviour {
        /// Answers like Codex. Before answering a rate limits read, it sends
        /// its own request with the same id and a notification.
        case working
        /// Exits without answering.
        case broken
        /// Completes the handshake, then never answers.
        case silent
        /// Completes the handshake, then answers every read with an error.
        case failing
        /// Completes the handshake, then exits when asked for the rate limits.
        case exitingOnRead
        /// Waits a second before completing the handshake.
        case slowHandshake
    }

    static let accountID = "123e4567-e89b-12d3-a456-426614174000"

    /// Writes the fake into a new temporary folder and returns its path.
    static func make(_ behaviour: Behaviour) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "hellocodex-fake-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let executable = directory.appending(path: "codex")
        try Data(script(for: behaviour).utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755], ofItemAtPath: executable.path)
        return executable
    }

    private static func script(for behaviour: Behaviour) -> String {
        let answers: String
        switch behaviour {
        case .working:
            answers = """
                if method == "account/rateLimits/read":
                    send({"id": id, "method": "item/tool/requestUserInput", "params": {}})
                    send({"method": "account/rateLimits/updated", "params": {}})
                    send({"id": id, "result": RATE_LIMITS})
                elif method == "account/read":
                    send({"id": id, "result": {"account": {"type": "chatgpt", "email": "me@example.com", "planType": "plus"}, "requiresOpenaiAuth": True}})
                """
        case .broken:
            return "#!/bin/sh\nexit 1\n"
        case .silent:
            answers = "pass"
        case .failing:
            answers = #"send({"id": id, "error": {"code": -32000, "message": "Not signed in"}})"#
        case .exitingOnRead:
            answers = """
                if method == "account/rateLimits/read":
                    sys.exit(0)
                """
        case .slowHandshake:
            answers = "pass"
        }
        let handshakeDelay = behaviour == .slowHandshake ? 1 : 0
        return """
            #!/usr/bin/env python3
            import json, sys, time

            RATE_LIMITS = {
                "accountId": "\(accountID)",
                "ordinaryUsageAllowed": True,
                "rateLimits": {
                    "limitId": "codex",
                    "primary": {"usedPercent": 14, "windowDurationMins": 300, "resetsAt": 1791000000},
                    "secondary": {"usedPercent": 21, "windowDurationMins": 10080, "resetsAt": 1791047411},
                },
                "rateLimitsByLimitId": None,
            }

            def send(message):
                sys.stdout.write(json.dumps(message) + "\\n")
                sys.stdout.flush()

            for line in sys.stdin:
                message = json.loads(line)
                id, method = message.get("id"), message.get("method")
                if id is None:
                    continue
                if method == "initialize":
                    time.sleep(\(handshakeDelay))
                    send({"id": id, "result": {}})
                    continue
            \(answers.split(separator: "\n").map { "    " + $0 }.joined(separator: "\n"))
            """
    }

    /// Whether a copy of this fake is still running.
    static func isRunning(_ executable: URL) throws -> Bool {
        let pgrep = Process()
        pgrep.executableURL = URL(filePath: "/usr/bin/pgrep")
        pgrep.arguments = ["-f", executable.path(percentEncoded: false)]
        pgrep.standardOutput = FileHandle.nullDevice
        try pgrep.run()
        pgrep.waitUntilExit()
        return pgrep.terminationStatus == 0
    }
}
