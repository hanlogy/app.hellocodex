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
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if let summary = weeklyLimit.summary {
                    WeeklyLimitHeader(summary: summary, variant: .compact)
                        .padding(.bottom, 14)
                    WeeklyLimitChart(summary: summary, variant: .compact)
                        .padding(.bottom, 16)
                    WeeklyLimitStats(summary: summary, variant: .compact)
                        .padding(.bottom, 14)
                } else {
                    WeeklyLimitStatusMessage(status: weeklyLimit.status, variant: .compact)
                        .padding(.bottom, 14)
                }
                Divider()
            }
            .padding(.horizontal, 16)
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
        .padding(.top, 16)
        .padding(.bottom, 6)
        .frame(width: 300)
        // Escape closes the popover, like a menu. It doesn't by itself, and
        // keys only reach a view that has focus.
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }
}
