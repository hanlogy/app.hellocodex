import AppKit
import SwiftUI
import Testing

@testable import DesignSystem

/// Whether a hairline placed `offset` points down shows at a display scale.
@MainActor
private func showsHairline(scale: Double, offset: Double) throws -> Bool {
    let host = NSHostingView(
        rootView: VStack(spacing: 0) {
            Spacer().frame(height: 10 + offset)
            Hairline(color: .black)
            Spacer().frame(height: 10)
        }
        .frame(width: 40)
        .background(Color.white)
        .environment(\.displayScale, scale))
    host.frame = CGRect(origin: .zero, size: host.fittingSize)
    host.layoutSubtreeIfNeeded()
    let bitmap = try #require(
        NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(host.bounds.width * scale),
            pixelsHigh: Int(host.bounds.height * scale), bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
            bitsPerPixel: 0))
    bitmap.size = host.bounds.size
    host.cacheDisplay(in: host.bounds, to: bitmap)
    return (0..<bitmap.pixelsHigh).contains {
        (bitmap.colorAt(x: bitmap.pixelsWide / 2, y: $0)?.brightnessComponent ?? 1) < 0.95
    }
}

@MainActor
struct HairlineTests {
    /// On standard and Retina displays, on a pixel boundary or between two.
    @Test(arguments: [1.0, 2.0], [0.0, 0.25, 0.5, 0.75])
    func showsWhereverItIsPlaced(scale: Double, offset: Double) throws {
        #expect(try showsHairline(scale: scale, offset: offset))
    }
}
