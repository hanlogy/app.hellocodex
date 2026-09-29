/// JSON-RPC methods of `codex app-server` that Hello Codex uses.
enum CodexMethod {
    static let initialize = "initialize"
    static let initialized = "initialized"
    static let readAccount = "account/read"
    static let readRateLimits = "account/rateLimits/read"
}
