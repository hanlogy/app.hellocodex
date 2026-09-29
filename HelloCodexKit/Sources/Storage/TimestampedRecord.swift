import Foundation

/// A record the store can file by the time it was recorded.
public protocol TimestampedRecord: Codable, Sendable {
    var recordedAt: Date { get }
}
