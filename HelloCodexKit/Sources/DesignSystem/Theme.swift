import SwiftUI

/// The app's colours, each with a light and a dark appearance. Views use only
/// these, never colours of their own.
public enum Theme {
    public static let background = color(.background)

    // Text, from strongest to weakest. `text` is also the chart line, the now
    // marker, and today's bar.
    public static let text = color(.text)
    /// Captions, section headings.
    public static let textSecondary = color(.textSecondary)
    /// Labels, day ticks, the legend.
    public static let textTertiary = color(.textTertiary)
    /// The footer.
    public static let textQuaternary = color(.textQuaternary)
    /// Days still to come.
    public static let textPlaceholder = color(.textPlaceholder)

    /// Something that needs attention, such as a limit running out.
    public static let warning = color(.warning)
    /// Something that's fine, such as a limit lasting until the reset.
    public static let success = color(.success)

    // Lines.
    public static let separatorStrong = color(.separatorStrong)
    public static let separatorRow = color(.separatorRow)

    // Charts and bars.
    public static let chartArea = color(.chartArea)
    public static let pace = color(.pace)
    public static let bar = color(.bar)
    public static let barEmpty = color(.barEmpty)
    public static let track = color(.track)

    /// A menu item under the pointer.
    public static let menuHover = color(.menuHover)

    /// The colours' names in the asset catalog. Every property above uses one,
    /// so tests can check each exists: a missing one would silently draw
    /// nothing.
    enum Name: String, CaseIterable {
        case background, text, textSecondary, textTertiary, textQuaternary, textPlaceholder
        case warning, success
        case separatorStrong, separatorRow
        case chartArea, pace, bar, barEmpty, track
        case menuHover
    }

    private static func color(_ name: Name) -> Color {
        Color(name.rawValue, bundle: .module)
    }
}
