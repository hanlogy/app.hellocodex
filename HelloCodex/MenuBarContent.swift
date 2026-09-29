import AppKit
import SwiftUI

/// What opens from the menu bar item.
struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading) {
            Button("Open Hello Codex") {
                openWindow(id: MainWindow.id)
                NSApp.activate()
            }
            .keyboardShortcut("o")
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
    }
}
