import DesignSystem
import SwiftUI
import WeeklyLimit

/// What shows instead of the week while there's none to show: "Loading…", or
/// why there isn't one. Nothing once the week is summarized.
public struct WeeklyLimitStatusMessage: View {
    private let status: WeeklyLimitMonitor.Status
    private let variant: Variant

    public init(status: WeeklyLimitMonitor.Status, variant: Variant = .full) {
        self.status = status
        self.variant = variant
    }

    public var body: some View {
        if let text = Self.text(for: status) {
            Text(text)
                .font(.system(size: variant == .full ? 13 : 12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    nonisolated static func text(for status: WeeklyLimitMonitor.Status) -> String? {
        switch status {
        case .loading: "Loading…"
        case .summarized: nil
        case .noWeeklyLimit: "Codex hasn’t reported a weekly limit."
        case .failed: "Couldn’t read the weekly limit from Codex."
        }
    }
}
