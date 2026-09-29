import Foundation

/// An append-only store of JSON lines, one file per UTC month, such as
/// `readings-2026-09.jsonl` for the prefix `readings`.
public struct MonthlyRecordStore<Record: TimestampedRecord>: Sendable {
    let directory: URL
    let filePrefix: String

    public init(directory: URL, filePrefix: String) {
        self.directory = directory
        self.filePrefix = filePrefix
    }

    /// Adds the record to the end of its month's file, creating the folder and
    /// the file when needed.
    public func append(_ record: Record) throws {
        var line = try Self.encoder.encode(record)
        line.append(UInt8(ascii: "\n"))

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = fileURL(for: Month(containing: record.recordedAt))
        guard FileManager.default.fileExists(atPath: file.path(percentEncoded: false)) else {
            try line.write(to: file)
            return
        }
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }

    /// The records from `start` to `end`, both included, oldest first. Lines
    /// that can't be read are skipped, so one bad line never hides the rest.
    public func records(from start: Date, to end: Date) throws -> [Record] {
        precondition(start <= end, "The time range must not end before it starts")

        let decoder = Self.decoder
        var records: [Record] = []
        for month in Month.range(from: start, to: end) {
            let data: Data
            do {
                data = try Data(contentsOf: fileURL(for: month))
            } catch CocoaError.fileReadNoSuchFile {
                continue
            }
            for line in data.split(separator: UInt8(ascii: "\n")) {
                guard let record = try? decoder.decode(Record.self, from: line) else {
                    continue
                }
                if record.recordedAt >= start && record.recordedAt <= end {
                    records.append(record)
                }
            }
        }
        return records.sorted { $0.recordedAt < $1.recordedAt }
    }

    private func fileURL(for month: Month) -> URL {
        directory.appending(path: "\(filePrefix)-\(month.name).jsonl", directoryHint: .notDirectory)
    }

    // Keys are sorted, so the same record is always written the same way.
    // Dates are ISO 8601 in UTC with milliseconds: 2026-09-28T09:16:47.791Z.
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(Self.timestampFormat))
        }
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            return try Date(text, strategy: Self.timestampFormat)
        }
        return decoder
    }

    private static var timestampFormat: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    }
}
