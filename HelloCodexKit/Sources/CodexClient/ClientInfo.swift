/// How the app introduces itself to Codex when it connects.
public struct ClientInfo: Encodable, Sendable {
    public let name: String
    public let title: String
    public let version: String

    public init(name: String, title: String, version: String) {
        self.name = name
        self.title = title
        self.version = version
    }
}
