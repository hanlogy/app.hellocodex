import AppKit
import SwiftUI

/// The main window. While it's open, the app has a Dock icon; once it's
/// closed, the app lives only in the menu bar.
struct MainWindow: View {
    static let id = "main"

    var body: some View {
        Color.clear
            .frame(minWidth: 760, minHeight: 600)
            .onAppear {
                NSApp.setActivationPolicy(.regular)
            }
            .onDisappear {
                NSApp.setActivationPolicy(.accessory)
            }
    }
}
