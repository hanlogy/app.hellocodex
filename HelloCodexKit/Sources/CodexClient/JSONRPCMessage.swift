import Foundation

/// A request we send; Codex answers it with the same `id`.
struct JSONRPCRequest<Params: Encodable>: Encodable {
    let id: Int
    let method: String
    let params: Params
}

/// A notification we send; Codex doesn't answer it.
struct JSONRPCNotification<Params: Encodable>: Encodable {
    let method: String
    let params: Params
}

/// Parameters for methods that take none.
struct NoParams: Encodable {}

/// The parts of any incoming line needed to route it: replies have an `id`
/// and no `method`; notifications have a `method` and no `id`; Codex's own
/// requests to us have both.
struct IncomingMessage: Decodable {
    struct ErrorBody: Decodable {
        let message: String
    }

    let id: Int?
    let method: String?
    let error: ErrorBody?
}

/// A successful reply, decoded once the caller knows the result's type.
struct JSONRPCReply<Result: Decodable>: Decodable {
    let result: Result
}

/// The parameters of `initialize`.
struct InitializeParams: Encodable, Sendable {
    let clientInfo: ClientInfo
}

/// Encodes one JSON-RPC message as a line.
enum JSONRPCWriter {
    static func line(_ message: some Encodable) throws -> Data {
        var data = try JSONEncoder().encode(message)
        data.append(UInt8(ascii: "\n"))
        return data
    }
}
