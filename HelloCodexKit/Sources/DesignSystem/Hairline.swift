import SwiftUI

/// A thin rule, 0.5 points but never less than a pixel: a thinner rectangle can
/// vanish on a standard display.
public struct Hairline: View {
    private let axis: Axis
    private let color: Color

    @Environment(\.displayScale) private var displayScale

    /// A horizontal rule is as wide as it's given; a vertical one as tall.
    public init(_ axis: Axis = .horizontal, color: Color) {
        self.axis = axis
        self.color = color
    }

    public var body: some View {
        let thickness = max(0.5, 1 / displayScale)
        Rectangle()
            .fill(color)
            .frame(
                width: axis == .vertical ? thickness : nil,
                height: axis == .horizontal ? thickness : nil)
    }
}
