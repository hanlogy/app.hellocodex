import Foundation
import Testing

@testable import WeeklyLimit

/// A history in a new temporary folder, removed after the test.
private func withHistory(_ body: (WeeklyLimitHistory, URL) throws -> Void) throws {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "hellocodex-history-\(UUID().uuidString)", directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    try body(WeeklyLimitHistory(accountDirectory: directory), directory)
}

private let resetsAt = Date(timeIntervalSince1970: 1_700_000_000)

struct WeeklyLimitHistoryTests {
    @Test func savesChangesAtOnceAndUnchangedReadingsEveryFiveMinutes() throws {
        try withHistory { history, _ in
            let used42 = WeeklyLimit(limitID: "codex", usedPercent: 42, resetsAt: resetsAt)
            let used43 = WeeklyLimit(limitID: "codex", usedPercent: 43, resetsAt: resetsAt)
            try history.record(used42, at: date("2026-09-28T10:00:00Z"))
            try history.record(used42, at: date("2026-09-28T10:01:00Z"))
            try history.record(used43, at: date("2026-09-28T10:02:00Z"))
            try history.record(used43, at: date("2026-09-28T10:03:00Z"))
            try history.record(used43, at: date("2026-09-28T10:07:00Z"))

            let saved = try history.records(
                from: date("2026-09-28T00:00:00Z"), to: date("2026-09-29T00:00:00Z"))

            #expect(
                saved.map(\.recordedAt)
                    == [
                        date("2026-09-28T10:00:00Z"), date("2026-09-28T10:02:00Z"),
                        date("2026-09-28T10:07:00Z"),
                    ])
        }
    }

    @Test(arguments: [
        WeeklyLimit(limitID: "other", usedPercent: 42, resetsAt: resetsAt),
        WeeklyLimit(
            limitID: "codex", usedPercent: 42, resetsAt: resetsAt.addingTimeInterval(604_800)),
        WeeklyLimit(limitID: "codex", usedPercent: 42, resetsAt: nil),
    ])
    func savesAnyChangeToTheReading(changed: WeeklyLimit) throws {
        try withHistory { history, _ in
            let original = WeeklyLimit(limitID: "codex", usedPercent: 42, resetsAt: resetsAt)
            try history.record(original, at: date("2026-09-28T10:00:00Z"))
            try history.record(changed, at: date("2026-09-28T10:01:00Z"))

            let saved = try history.records(
                from: date("2026-09-28T00:00:00Z"), to: date("2026-09-29T00:00:00Z"))

            #expect(saved.count == 2)
        }
    }

    @Test func writesTheSameFileAndLinesAsEarlierVersions() throws {
        try withHistory { history, directory in
            let limit = WeeklyLimit(
                limitID: "codex", usedPercent: 15,
                resetsAt: Date(timeIntervalSince1970: 1_791_047_411))
            try history.record(limit, at: date("2026-09-28T09:16:47.791Z"))

            let contents = try String(
                contentsOf: directory.appending(path: "weekly-limit-2026-09.jsonl"), encoding: .utf8
            )
            #expect(
                contents
                    == #"{"limitId":"codex","recordedAt":"2026-09-28T09:16:47.791Z","resetsAt":1791047411,"usedPercent":15}"#
                    + "\n")
        }
    }

    @Test func readsLinesWrittenByEarlierVersions() throws {
        try withHistory { _, directory in
            // The format earlier versions wrote, including a missing reset time.
            let lines = """
                {"recordedAt":"2026-09-28T09:16:47.791Z","limitId":"codex","usedPercent":15,"resetsAt":1791047411}
                {"recordedAt":"2026-09-28T09:26:59.897Z","limitId":"codex","usedPercent":15.5,"resetsAt":null}
                """
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            try Data(lines.utf8).write(to: directory.appending(path: "weekly-limit-2026-09.jsonl"))

            let saved = try WeeklyLimitHistory(accountDirectory: directory).records(
                from: date("2026-09-28T00:00:00Z"), to: date("2026-09-29T00:00:00Z"))

            #expect(saved.map(\.usedPercent) == [15, 15.5])
            #expect(saved.map(\.resetsAt) == [1_791_047_411, nil])
        }
    }
}
