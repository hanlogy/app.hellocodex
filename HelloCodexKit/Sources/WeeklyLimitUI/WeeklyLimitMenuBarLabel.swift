import DesignSystem
import SwiftUI
import WeeklyLimit

/// The menu bar item: the app's logo, followed by what's left of the weekly
/// limit once it's known, and what today used: "68% (−3%)".
public struct WeeklyLimitMenuBarLabel: View {
    private let limit: WeeklyLimit?
    private let summary: WeeklySummary?
    private let icon: Image

    public init(limit: WeeklyLimit?, summary: WeeklySummary?, icon: Image) {
        self.limit = limit
        self.summary = summary
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            icon
            if let text = WeeklyLimitMenuBarText.text(
                percentLeft: limit?.percentLeft, summary: summary)
            {
                Text(text)
            }
        }
    }
}
