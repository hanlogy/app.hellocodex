import Foundation

/// The folder where the app keeps its files, with one subfolder per Codex
/// account.
public struct DataDirectory: Sendable {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// The app's folder in `~/Library/Application Support`, named after its
    /// bundle identifier. Debug builds use their own folder, so they never
    /// touch the installed app's data.
    public static func applicationSupport(
        bundleIdentifier: String,
        isDebugBuild: Bool
    ) -> DataDirectory {
        let applicationSupport = URL.applicationSupportDirectory
        let name = folderName(bundleIdentifier: bundleIdentifier, isDebugBuild: isDebugBuild)
        return DataDirectory(
            url: applicationSupport.appending(path: name, directoryHint: .isDirectory))
    }

    private static func folderName(bundleIdentifier: String, isDebugBuild: Bool) -> String {
        isDebugBuild ? "\(bundleIdentifier).dev" : bundleIdentifier
    }

    /// Where one Codex account's files are kept, so accounts never mix.
    public func accountDirectory(for key: AccountFolderKey) -> URL {
        url.appending(path: "accounts", directoryHint: .isDirectory)
            .appending(path: key.rawValue, directoryHint: .isDirectory)
    }
}
