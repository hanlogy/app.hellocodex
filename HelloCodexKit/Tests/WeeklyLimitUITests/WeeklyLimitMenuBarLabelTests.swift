import Testing

@testable import WeeklyLimitUI

struct WeeklyLimitMenuBarLabelTests {
    @Test(arguments: [(79.0, "79%"), (79.4, "79%"), (79.5, "80%"), (100, "100%"), (0, "0%")])
    func showsWhatIsLeftToAWholePercent(percent: Double, text: String) {
        #expect(WeeklyLimitMenuBarLabel.text(forPercentLeft: percent) == text)
    }
}
