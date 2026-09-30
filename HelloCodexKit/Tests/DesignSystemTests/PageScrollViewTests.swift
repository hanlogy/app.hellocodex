import AppKit
import SwiftUI
import Testing

@testable import DesignSystem

/// A page taller than its window, in a real window.
@MainActor
private func pageScrollView() throws -> (NSWindow, NSScrollView) {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled],
        backing: .buffered, defer: false)
    window.contentView = NSHostingView(
        rootView: PageScrollView { Color.white.frame(height: 2000).frame(maxWidth: .infinity) })
    window.contentView?.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    return (window, try #require(scrollView(in: window.contentView)))
}

@MainActor
private func scrollView(in view: NSView?) -> NSScrollView? {
    guard let view else { return nil }
    if let scrollView = view as? NSScrollView { return scrollView }
    return view.subviews.lazy.compactMap { scrollView(in: $0) }.first
}

@MainActor
struct PageScrollViewTests {
    /// Whatever the system prefers, such as the wide style when a mouse is
    /// connected.
    @Test func usesTheOverlayScrollBar() throws {
        let (_, scrollView) = try pageScrollView()

        #expect(scrollView.scrollerStyle == .overlay)

        NotificationCenter.default.post(
            name: NSScroller.preferredScrollerStyleDidChangeNotification, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        #expect(scrollView.scrollerStyle == .overlay)
    }

    /// The overlay scroll bar is drawn over the page, so it takes no width.
    @Test func givesThePageTheFullWidth() throws {
        let (_, scrollView) = try pageScrollView()

        #expect(scrollView.contentView.frame.width == scrollView.frame.width)
        #expect(scrollView.documentView?.frame.width == scrollView.frame.width)
    }
}
