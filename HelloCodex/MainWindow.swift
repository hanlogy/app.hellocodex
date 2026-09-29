import AppKit
import DesignSystem
import SwiftUI

/// The main window: an empty title bar with the traffic lights, and the week's
/// sections scrolling below it. While it's open, the app has a Dock icon; once
/// it's closed, the app lives only in the menu bar.
struct MainWindow: View {
    static let id = "main"

    var body: some View {
        ScrollView {
            // The week's sections go here.
        }
        .frame(minWidth: 760, minHeight: 600)
        .background(Theme.background)
        .background(TitleBar())
        .onAppear {
            NSApp.setActivationPolicy(.regular)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
