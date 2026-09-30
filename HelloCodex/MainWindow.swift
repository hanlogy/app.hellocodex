import AppKit
import DesignSystem
import SwiftUI
import WeeklyLimit
import WeeklyLimitUI

/// The main window: the week's sections, scrolling. While it's open, the app
/// has a Dock icon; once it's closed, the app lives only in the menu bar.
struct MainWindow: View {
    static let id = "main"

    let weeklyLimit: WeeklyLimitMonitor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if let summary = weeklyLimit.summary {
                    WeeklyLimitHeader(summary: summary)
                    WeeklyLimitChart(summary: summary)
                    WeeklyLimitStats(summary: summary)
                    WeeklyLimitDailyUsage(summary: summary)
                } else {
                    WeeklyLimitStatusMessage(status: weeklyLimit.status)
                }
            }
            .padding(EdgeInsets(top: 20, leading: 40, bottom: 36, trailing: 40))
        }
        .frame(minWidth: 760, minHeight: 600)
        .background(Theme.background)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
