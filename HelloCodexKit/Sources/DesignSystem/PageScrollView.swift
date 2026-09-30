import AppKit
import SwiftUI

/// A vertically scrolling page with the thin overlay scroll bar, which shows
/// while the page scrolls and while the pointer moves over it. Content fades
/// out at the top edge as it scrolls up; the scroll bar doesn't.
///
/// macOS uses the wide scroll bar when a mouse is connected, and SwiftUI's
/// scroll view then lays the page out as if the bar took no width whenever the
/// page is taller than the part below the title bar but not than the whole
/// view, so the page ran under the bar. The page is an AppKit scroll view
/// instead, which can keep the overlay style: it takes no width, and looks the
/// same for everyone.
public struct PageScrollView<Content: View>: View {
    /// How far down from the top the page fades in as it scrolls.
    public static var fadeHeight: CGFloat { 20 }

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        OverlayScrollViewBridge(content: content, fadeHeight: Self.fadeHeight)
    }
}

private struct OverlayScrollViewBridge<Content: View>: NSViewRepresentable {
    let content: Content
    let fadeHeight: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        OverlayScrollView(page: page(in: context), fadeHeight: fadeHeight)
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        (scrollView as? OverlayScrollView)?.page.rootView = page(in: context)
    }

    /// The content, with the environment it has where the page is.
    private func page(in context: Context) -> AnyView {
        AnyView(content.environment(\.self, context.environment))
    }
}

private final class OverlayScrollView: NSScrollView {
    let page: NSHostingView<AnyView>
    private let fade = TopFade()
    private let fadeHeight: CGFloat

    init(page content: AnyView, fadeHeight: CGFloat) {
        page = NSHostingView(rootView: content)
        self.fadeHeight = fadeHeight
        super.init(frame: .zero)
        drawsBackground = false
        hasVerticalScroller = true
        super.scrollerStyle = .overlay

        // As wide as the scroll view, and as tall as the page.
        page.translatesAutoresizingMaskIntoConstraints = false
        documentView = page
        NSLayoutConstraint.activate([
            page.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            page.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            page.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])

        // Stays at the top while the page scrolls under it, below the scroll
        // bar, so only the content fades.
        addFloatingSubview(fade, for: .vertical)
    }

    override func tile() {
        super.tile()
        fade.frame = NSRect(x: 0, y: 0, width: contentView.bounds.width, height: fadeHeight)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("OverlayScrollView isn't made from a nib")
    }

    /// Always the overlay style: the scroll view takes the system's style
    /// again whenever it changes, such as when a mouse is connected.
    override var scrollerStyle: NSScroller.Style {
        get { .overlay }
        set { super.scrollerStyle = .overlay }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if trackingAreas.isEmpty {
            addTrackingArea(
                NSTrackingArea(
                    rect: .zero,
                    options: [
                        .mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow, .inVisibleRect,
                    ],
                    owner: self))
        }
    }

    // Shows the scroll bar while the pointer moves over the page, so it's
    // clear the page scrolls; it fades out again by itself.
    override func mouseEntered(with event: NSEvent) {
        flashScrollers()
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        flashScrollers()
    }
}

/// The window's background fading to clear, top to bottom. It never takes a
/// click: they go to the page below it.
private final class TopFade: NSHostingView<LinearGradient> {
    required init() {
        super.init(
            rootView: LinearGradient(
                colors: [Theme.background, Theme.background.opacity(0)], startPoint: .top,
                endPoint: .bottom))
    }

    @available(*, unavailable)
    required init(rootView: LinearGradient) {
        fatalError("TopFade draws only its own gradient")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("TopFade isn't made from a nib")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}
