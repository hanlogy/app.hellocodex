import Foundation
import Testing

@testable import Storage

struct MonthTests {
    @Test func coversEveryMonthFromStartToEndAcrossAYear() {
        let months = Month.range(
            from: date("2026-11-15T00:00:00Z"), to: date("2027-01-02T00:00:00Z"))

        #expect(months.map(\.name) == ["2026-11", "2026-12", "2027-01"])
    }

    @Test func isEmptyWhenTheEndIsBeforeTheStart() {
        let months = Month.range(
            from: date("2026-10-01T00:00:00Z"), to: date("2026-09-01T00:00:00Z"))

        #expect(months.isEmpty)
    }
}
