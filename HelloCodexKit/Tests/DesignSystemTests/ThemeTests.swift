import AppKit
import Testing

@testable import DesignSystem

struct ThemeTests {
    @Test(arguments: Theme.Name.allCases)
    func findsEveryColourInTheAssetCatalog(name: Theme.Name) {
        #expect(NSColor(named: name.rawValue, bundle: .module) != nil)
    }

    @Test func hasALightAndADarkAppearance() throws {
        let text = try #require(NSColor(named: "text", bundle: .module))

        let light = try #require(Self.hex(of: text, in: .aqua))
        let dark = try #require(Self.hex(of: text, in: .darkAqua))

        #expect(light == "1D1D1F")
        #expect(dark == "F5F5F7")
    }

    private static func hex(of color: NSColor, in appearance: NSAppearance.Name) -> String? {
        var hex: String?
        NSAppearance(named: appearance)?.performAsCurrentDrawingAppearance {
            guard let rgb = color.usingColorSpace(.sRGB) else {
                return
            }
            hex = String(
                format: "%02X%02X%02X", Int((rgb.redComponent * 255).rounded()),
                Int((rgb.greenComponent * 255).rounded()), Int((rgb.blueComponent * 255).rounded()))
        }
        return hex
    }
}
