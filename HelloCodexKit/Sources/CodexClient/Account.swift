/// The account signed in to Codex, from `account/read`. Only ChatGPT accounts
/// have an email; API key and Amazon Bedrock accounts don't.
public struct Account: Decodable, Equatable, Sendable {
    public let type: String
    public let email: String?

    public init(type: String, email: String?) {
        self.type = type
        self.email = email
    }
}

/// The `account/read` response.
struct AccountResponse: Decodable {
    let account: Account?
}
