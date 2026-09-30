import DesignSystem
import WeeklyLimit

/// The menu bar item's text: what's left of the weekly limit, and how much of
/// it today used, once that's at least a percent: "68% (−3%)".
enum WeeklyLimitMenuBarText {
    /// nil until the limit is known.
    static func text(percentLeft: Double?, summary: WeeklySummary?) -> String? {
        guard let percentLeft else {
            return nil
        }
        let left = DisplayText.percent(percentLeft)
        guard let summary, let used = WeeklyLimitText.todayGroup(of: summary)?.usedPercent,
            used.rounded() != 0
        else {
            return left
        }
        // In brackets, as a note on what's left, so it doesn't read as "68%
        // minus 3%".
        return "\(left) (\(WeeklyLimitText.usedChange(used)))"
    }
}
