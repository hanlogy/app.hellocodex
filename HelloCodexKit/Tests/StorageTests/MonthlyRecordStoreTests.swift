import Foundation
import Testing

@testable import Storage

private struct Reading: TimestampedRecord, Equatable {
    let recordedAt: Date
    let value: Int
}

/// A store in a new temporary folder, removed after the test.
private func withStore(
    _ body: (MonthlyRecordStore<Reading>, URL) throws -> Void
) throws {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "hellocodex-storage-\(UUID().uuidString)", directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    try body(MonthlyRecordStore(directory: directory, filePrefix: "readings"), directory)
}

struct MonthlyRecordStoreTests {
    @Test func readsBackWhatItAppends() throws {
        try withStore { store, _ in
            let first = Reading(recordedAt: date("2026-09-28T09:00:00Z"), value: 1)
            let second = Reading(recordedAt: date("2026-09-28T10:00:00Z"), value: 2)
            try store.append(first)
            try store.append(second)

            #expect(
                try store.records(
                    from: date("2026-09-01T00:00:00Z"), to: date("2026-09-30T00:00:00Z"))
                    == [first, second])
        }
    }

    @Test func writesOneLinePerRecordInItsUTCMonthsFile() throws {
        try withStore { store, directory in
            try store.append(Reading(recordedAt: date("2026-09-28T09:16:47.791Z"), value: 15))

            let contents = try String(
                contentsOf: directory.appending(path: "readings-2026-09.jsonl"), encoding: .utf8)
            #expect(contents == #"{"recordedAt":"2026-09-28T09:16:47.791Z","value":15}"# + "\n")
        }
    }

    @Test func readsTimestampsWrittenByEarlierVersions() throws {
        try withStore { store, directory in
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            try Data(#"{"recordedAt":"2026-09-28T09:16:47.791Z","value":15}"#.utf8)
                .write(to: directory.appending(path: "readings-2026-09.jsonl"))

            #expect(
                try store.records(
                    from: date("2026-09-01T00:00:00Z"), to: date("2026-09-30T00:00:00Z"))
                    == [Reading(recordedAt: date("2026-09-28T09:16:47.791Z"), value: 15)])
        }
    }

    @Test func readsATimeRangeAcrossMonthsAndYearsInTimestampOrder() throws {
        try withStore { store, _ in
            let lastOfYear = Reading(recordedAt: date("2026-12-31T23:55:00Z"), value: 42)
            let firstOfYear = Reading(recordedAt: date("2027-01-01T00:05:00Z"), value: 43)
            let afterRange = Reading(recordedAt: date("2027-01-01T00:10:00Z"), value: 44)
            try store.append(firstOfYear)
            try store.append(afterRange)
            try store.append(lastOfYear)

            #expect(
                try store.records(from: lastOfYear.recordedAt, to: firstOfYear.recordedAt)
                    == [lastOfYear, firstOfYear])
        }
    }

    @Test func filesByUTCMonthWhateverTheLocalTime() throws {
        try withStore { store, directory in
            try store.append(Reading(recordedAt: date("2026-09-30T23:30:00Z"), value: 1))
            try store.append(Reading(recordedAt: date("2026-10-01T00:30:00Z"), value: 2))

            let files = try FileManager.default.contentsOfDirectory(
                atPath: directory.path(percentEncoded: false))
            #expect(Set(files) == ["readings-2026-09.jsonl", "readings-2026-10.jsonl"])
        }
    }

    @Test func returnsNothingWhenNoFileExists() throws {
        try withStore { store, _ in
            let records = try store.records(
                from: date("2026-09-01T00:00:00Z"), to: date("2026-09-07T00:00:00Z"))

            #expect(records.isEmpty)
        }
    }

    @Test func skipsLinesItCannotReadAndKeepsTheRest() throws {
        try withStore { store, directory in
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            let lines = [
                #"{"recordedAt":"2026-09-28T09:00:00.000Z","value":1}"#,
                "not json",
                #"{"recordedAt":"yesterday","value":2}"#,
                #"{"recordedAt":"2026-09-28T09:10:00.000Z"}"#,
                "",
                #"{"recordedAt":"2026-09-28T09:20:00.000Z","value":3}"#,
            ]
            try Data(lines.joined(separator: "\n").utf8)
                .write(to: directory.appending(path: "readings-2026-09.jsonl"))

            let values = try store.records(
                from: date("2026-09-28T00:00:00Z"), to: date("2026-09-29T00:00:00Z")
            ).map(\.value)
            #expect(values == [1, 3])
        }
    }
}
