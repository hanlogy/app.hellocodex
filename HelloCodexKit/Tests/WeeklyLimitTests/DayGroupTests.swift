import Foundation
import Testing

@testable import WeeklyLimit

private func day(_ used: Double?) -> DayUsage {
    DayUsage(startsAt: Date(timeIntervalSince1970: 0), usedPercent: used)
}

struct DayGroupTests {
    @Test func mergesDaysWithoutReadingsIntoTheNextDayWithReadings() {
        let groups = DayGroup.groups(
            of: [day(0), day(0), day(21), day(nil)], haveReadings: [false, false, true, false])

        #expect(
            groups == [
                DayGroup(firstDay: 0, lastDay: 2, usedPercent: 21),
                DayGroup(firstDay: 3, lastDay: 3, usedPercent: nil),
            ])
    }

    @Test func keepsDaysWithReadingsOnTheirOwn() {
        let groups = DayGroup.groups(
            of: [day(9), day(0), day(5), day(7)], haveReadings: [true, false, true, true])

        #expect(
            groups == [
                DayGroup(firstDay: 0, lastDay: 0, usedPercent: 9),
                DayGroup(firstDay: 1, lastDay: 2, usedPercent: 5),
                DayGroup(firstDay: 3, lastDay: 3, usedPercent: 7),
            ])
    }

    @Test func endsAGroupAtTodayEvenWithoutReadings() {
        let groups = DayGroup.groups(of: [day(3), day(4)], haveReadings: [false, false])

        #expect(groups == [DayGroup(firstDay: 0, lastDay: 1, usedPercent: 7)])
    }

    @Test func hasNoGroupsWithoutDays() {
        #expect(DayGroup.groups(of: [], haveReadings: []).isEmpty)
    }
}
