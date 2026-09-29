import CryptoKit
import Foundation

/// A Codex account's folder name: its ID when that's a UUID, otherwise a hash
/// of its email, so the name is always safe as a path component.
public struct AccountFolderKey: Hashable, Sendable {
    public let rawValue: String

    /// Returns nil when neither the ID nor the email identifies the account.
    public init?(accountID: String?, email: String?) {
        if let accountID, UUID(uuidString: accountID) != nil {
            rawValue = accountID
            return
        }
        let normalizedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let normalizedEmail, !normalizedEmail.isEmpty else {
            return nil
        }
        let hash = SHA256.hash(data: Data(normalizedEmail.utf8))
        rawValue = "email-" + hash.map { String(format: "%02x", $0) }.joined()
    }
}
