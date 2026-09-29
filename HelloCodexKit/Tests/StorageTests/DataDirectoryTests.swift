import Foundation
import Testing

@testable import Storage

struct DataDirectoryTests {
    @Test func namesTheFolderInApplicationSupportAfterTheBundleIdentifier() {
        let directory = DataDirectory.applicationSupport(
            bundleIdentifier: "com.hanlogy.hellocodex", isDebugBuild: false)

        #expect(
            directory.url
                == URL.applicationSupportDirectory.appending(
                    path: "com.hanlogy.hellocodex", directoryHint: .isDirectory))
    }

    @Test func givesDebugBuildsTheirOwnFolder() {
        let directory = DataDirectory.applicationSupport(
            bundleIdentifier: "com.hanlogy.hellocodex", isDebugBuild: true)

        #expect(
            directory.url
                == URL.applicationSupportDirectory.appending(
                    path: "com.hanlogy.hellocodex.dev", directoryHint: .isDirectory))
    }

    @Test func keepsEachAccountInItsOwnFolder() throws {
        let directory = DataDirectory(url: URL(filePath: "/data"))
        let key = try #require(
            AccountFolderKey(accountID: "123e4567-e89b-12d3-a456-426614174000", email: nil))

        #expect(
            directory.accountDirectory(for: key).path(percentEncoded: false)
                == "/data/accounts/123e4567-e89b-12d3-a456-426614174000/")
    }
}
