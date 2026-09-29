import AppKit
import DesignSystem
import SwiftUI
import WeeklyLimit
import WeeklyLimitUI

/// The popover that opens from the menu bar item: the week at a glance, and
/// the app's actions.
struct MenuBarContent: View {
    let weeklyLimit: WeeklyLimitMonitor

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let summary = weeklyLimit.summary {
                VStack(alignment: .leading, spacing: 0) {
                    WeeklyLimitHeader(summary: summary, variant: .compact)
                        .padding(.bottom, 14)
                    WeeklyLimitChart(summary: summary, variant: .compact)
                        .padding(.bottom, 16)
                    WeeklyLimitStats(summary: summary, variant: .compact)
                        .padding(.bottom, 14)
                    Hairline(color: Theme.separator)
                }
                .padding(.horizontal, 16)
            }
            VStack(spacing: 0) {
                MenuItem("Open Hello Codex", key: "o") {
                    // The popover doesn't close by itself when another window
                    // comes to the front.
                    dismiss()
                    openWindow(id: MainWindow.id)
                    NSApp.activate()
                }
                MenuItem("Quit", key: "q") {
                    NSApp.terminate(nil)
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 6)
        }
        .padding(.top, weeklyLimit.summary == nil ? 0 : 16)
        .padding(.bottom, 6)
        .frame(width: 300)
        // Escape closes the popover, like a menu. It doesn't by itself.
        .background {
            Button("Close", action: dismiss.callAsFunction)
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }
}
