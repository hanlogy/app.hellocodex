import SwiftUI

extension Text {
    /// Text with its characters moved closer together (a negative `kerning`)
    /// or further apart. Only the space between characters changes: kerning
    /// the last one too makes a window clip the end of its glyph.
    public init(_ string: String, kerningBetweenCharacters kerning: CGFloat) {
        guard let last = string.last else {
            self.init(string)
            return
        }
        var spaced = AttributedString(String(string.dropLast()))
        spaced.kern = kerning
        self.init(spaced + AttributedString(String(last)))
    }
}
