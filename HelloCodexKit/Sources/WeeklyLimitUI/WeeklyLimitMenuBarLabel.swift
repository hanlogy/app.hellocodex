import SwiftUI
import WeeklyLimit

/// The menu bar item: the app's logo, followed by what's left of the weekly
/// limit once it's known.
public struct WeeklyLimitMenuBarLabel: View {
    private let limit: WeeklyLimit?
    private let icon: Image

    public init(limit: WeeklyLimit?, icon: Image) {
        self.limit = limit
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            icon
            if let limit {
                Text(Self.text(forPercentLeft: limit.percentLeft))
            }
        }
    }

    /// "79%": what's left, to a whole percent.
    nonisolated static func text(forPercentLeft percent: Double) -> String {
        "\(Int(percent.rounded()))%"
    }
}
