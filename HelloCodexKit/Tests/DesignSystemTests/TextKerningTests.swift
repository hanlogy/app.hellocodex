import AppKit
import SwiftUI
import Testing

@testable import DesignSystem

/// How much of the last glyph's right edge is a straight vertical cut: the
/// dark pixels in the rightmost column with any ink, as a share of the text's
/// height. A clipped "%" ends in a cut; a whole one ends on a curve.
@MainActor
private func shareOfInkInLastColumn(_ text: Text) throws -> Double {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 260, height: 110), styleMask: [.titled],
        backing: .buffered, defer: false)
    // Drawn by a real window's hosting view: ImageRenderer doesn't clip.
    let host = NSHostingView(
        rootView: ScrollView {
            HStack {
                text
                Spacer()
            }.padding(20)
        }.background(Color.white))
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
    host.cacheDisplay(in: host.bounds, to: bitmap)

    func isInk(_ x: Int, _ y: Int) -> Bool {
        (bitmap.colorAt(x: x, y: y)?.brightnessComponent ?? 1) < 0.5
    }
    let (width, height) = (bitmap.pixelsWide, bitmap.pixelsHigh)
    let inkColumns = (0..<width).filter { x in (0..<height).contains { isInk(x, $0) } }
    let inkRows = (0..<height).filter { y in (0..<width).contains { isInk($0, y) } }
    let lastColumn = try #require(inkColumns.last)
    let inkInLastColumn = (0..<height).filter { isInk(lastColumn, $0) }.count
    return Double(inkInLastColumn) / Double(inkRows.count)
}

@MainActor
struct TextKerningTests {
    @Test func keepsTheLastCharacterWholeWhenMovingCharactersTogether() throws {
        let text = Text("75%", kerningBetweenCharacters: -3.6)
            .font(.system(size: 72, weight: .light, design: .monospaced))

        #expect(try shareOfInkInLastColumn(text) < 0.4)
    }
}
