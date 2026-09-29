import AppKit
import DesignSystem
import SwiftUI

/// Gives the window the taller, unified title bar with the traffic lights
/// centred in it, no title, and the window's own background with no line
/// below it. It uses an empty AppKit toolbar: with no items there's nothing to
/// see or customize.
struct TitleBar: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // The window is only known once the view is in it.
        DispatchQueue.main.async {
            if let window = view.window {
                Self.configure(window)
            }
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}

    private static func configure(_ window: NSWindow) {
        let toolbar = NSToolbar()
        toolbar.displayMode = .iconOnly
        if #available(macOS 15.0, *) {
            toolbar.allowsDisplayModeCustomization = false
        }
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor(Theme.background)
    }
}
