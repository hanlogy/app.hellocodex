import CodexClient
import Foundation
import Storage
import WeeklyLimit

/// The app's one instance of each infrastructure service, and the features
/// built on them.
@MainActor
final class AppServices {
    let weeklyLimit: WeeklyLimitMonitor
    private let codex: CodexClient

    init(bundle: Bundle = .main) {
        guard let bundleIdentifier = bundle.bundleIdentifier else {
            preconditionFailure("The app has no bundle identifier to name its data folder")
        }
        #if DEBUG
            let isDebugBuild = true
        #else
            let isDebugBuild = false
        #endif
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        codex = CodexClient(
            clientInfo: ClientInfo(
                name: "hellocodex", title: "Hello Codex", version: version ?? "0"))
        weeklyLimit = WeeklyLimitMonitor(
            codex: codex,
            dataDirectory: .applicationSupport(
                bundleIdentifier: bundleIdentifier,
                isDebugBuild: isDebugBuild))
    }

    /// Starts reading from Codex.
    func start() {
        weeklyLimit.start()
        Task { [codex] in
            await codex.start()
        }
    }
}
