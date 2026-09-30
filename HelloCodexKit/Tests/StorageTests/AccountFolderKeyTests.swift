import Testing

@testable import Storage

struct AccountFolderKeyTests {
    private let accountID = "123e4567-e89b-12d3-a456-426614174000"
    // SHA-256 of "me@example.com". The folder name must never change, or an
    // account's readings would be left behind in its old folder.
    private let emailKey = "email-8c2a47d3bdb8d3096a6479f53eac3b724291db5f1c31611100f675be5537329d"

    @Test func usesTheAccountIDWhenItIsAUUID() {
        #expect(
            AccountFolderKey(accountID: accountID, email: "me@example.com")?.rawValue == accountID)
    }

    @Test func keepsTheIDAsCodexSendsIt() {
        let uppercased = accountID.uppercased()

        #expect(AccountFolderKey(accountID: uppercased, email: nil)?.rawValue == uppercased)
    }

    @Test(arguments: [nil, "", "../outside", "not-a-uuid"])
    func fallsBackToAHashOfTheEmail(accountID: String?) {
        #expect(
            AccountFolderKey(accountID: accountID, email: "me@example.com")?.rawValue == emailKey)
    }

    @Test func hashesTheSameAddressTheSameWayInAnyCase() {
        #expect(AccountFolderKey(accountID: nil, email: "  Me@Example.COM ")?.rawValue == emailKey)
    }

    @Test(arguments: [nil, "", "   "])
    func isNilWhenNothingIdentifiesTheAccount(email: String?) {
        #expect(AccountFolderKey(accountID: nil, email: email) == nil)
    }
}
