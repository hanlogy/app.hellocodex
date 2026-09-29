import Foundation
import Testing

@testable import WeeklyLimit

struct WeekTests {
    @Test func spansTheSevenDaysBeforeTheReset() {
        let resetsAt = Date(timeIntervalSince1970: 1_791_047_411)

        let week = Week(endingAt: resetsAt)

        #expect(week.startsAt == resetsAt.addingTimeInterval(-7 * 24 * 60 * 60))
        #expect(week.resetsAt == resetsAt)
    }

    @Test func listsTheWeekStartAndEachMidnightBeforeTheReset() {
        let week = Week(endingAt: local(2026, 10, 2, 9))

        #expect(
            week.dayStarts(in: stockholm)
                == [
                    local(2026, 9, 25, 9), local(2026, 9, 26), local(2026, 9, 27),
                    local(2026, 9, 28),
                    local(2026, 9, 29), local(2026, 9, 30), local(2026, 10, 1), local(2026, 10, 2),
                ])
    }

    @Test func findsEachMidnightWhenTheClocksGoBack() {
        // Sunday 25 October 2026 has 25 hours in Stockholm.
        let week = Week(endingAt: local(2026, 10, 28, 9))

        let starts = week.dayStarts(in: stockholm)

        #expect(starts.count == 8)
        #expect(starts.dropFirst().allSatisfy { stockholm.component(.hour, from: $0) == 0 })
        #expect(starts.contains(local(2026, 10, 26)))
    }

    @Test func findsEachMidnightWhenTheClocksGoForward() {
        // Sunday 29 March 2026 has 23 hours in Stockholm.
        let week = Week(endingAt: local(2026, 4, 1, 9))

        let starts = week.dayStarts(in: stockholm)

        #expect(starts.count == 8)
        #expect(starts.dropFirst().allSatisfy { stockholm.component(.hour, from: $0) == 0 })
        #expect(starts.contains(local(2026, 3, 30)))
    }

    @Test func hasSevenDaysWhenTheWeekStartsAtMidnight() {
        let week = Week(endingAt: local(2026, 10, 2))

        #expect(week.dayStarts(in: stockholm).count == 7)
    }
}
