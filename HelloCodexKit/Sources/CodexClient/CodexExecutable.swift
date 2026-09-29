import Foundation

/// Where to look for the `codex` executable.
public enum CodexExecutable {
    /// Apps opened from Finder get a minimal `PATH`, so also check where
    /// Homebrew and the ChatGPT app install Codex.
    static let knownLocations = [
        "/opt/homebrew/bin/codex",
        "/usr/local/bin/codex",
        "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
    ]

    /// Every executable `codex` on `PATH` and in the known locations, in that
    /// order, without duplicates.
    public static func candidates(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> [URL] {
        let onPath = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { "\($0)/codex" }
        var seen = Set<String>()
        return (onPath + knownLocations)
            .filter { seen.insert($0).inserted }
            .filter { FileManager.default.isExecutableFile(atPath: $0) }
            .map { URL(filePath: $0) }
    }
}
