import Testing
import WeeklyLimit

@testable import WeeklyLimitUI

struct WeeklyLimitStatusMessageTests {
    @Test(arguments: [
        (WeeklyLimitMonitor.Status.loading, "Loading…"),
        (.noWeeklyLimit, "Codex hasn’t reported a weekly limit."),
        (.failed, "Couldn’t read the weekly limit from Codex."),
    ])
    func explainsWhyThereIsNoWeekToShow(status: WeeklyLimitMonitor.Status, text: String) {
        #expect(WeeklyLimitStatusMessage.text(for: status) == text)
    }

    @Test func showsNothingOnceTheWeekIsSummarized() {
        #expect(WeeklyLimitStatusMessage.text(for: .summarized) == nil)
    }
}
