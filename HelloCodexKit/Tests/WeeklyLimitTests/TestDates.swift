import Foundation

/// A fixed test date, written with or without milliseconds.
func date(_ text: String) -> Date {
    let withMilliseconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    guard
        let date = (try? Date(text, strategy: withMilliseconds))
            ?? (try? Date(text, strategy: .iso8601))
    else {
        fatalError("Not an ISO 8601 date: \(text)")
    }
    return date
}
