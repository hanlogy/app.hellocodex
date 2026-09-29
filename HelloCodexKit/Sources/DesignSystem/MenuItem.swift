import SwiftUI

/// An action in a popover's menu, with its keyboard shortcut: "Quit ⌘Q".
/// It's highlighted under the pointer, like a menu item.
public struct MenuItem: View {
    private let title: String
    private let key: KeyEquivalent
    private let action: () -> Void

    @State private var isHovered = false

    /// `key` is pressed with Command.
    public init(_ title: String, key: KeyEquivalent, action: @escaping () -> Void) {
        self.title = title
        self.key = key
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("⌘\(String(key.character).uppercased())")
                    .foregroundStyle(Theme.textTertiary)
            }
            .font(.system(size: 12.5))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6).fill(Theme.menuHover.opacity(isHovered ? 1 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(key)
        .onHover { isHovered = $0 }
    }
}
