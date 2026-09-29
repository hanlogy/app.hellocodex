import SwiftUI

/// A labelled value in a ``StatRow``.
public struct Stat: Equatable, Sendable {
    /// A colour for a value that's good or bad news.
    public enum Tone: Sendable {
        case success, warning
    }

    public let label: String
    public let value: String
    public let tone: Tone?

    public init(label: String, value: String, tone: Tone? = nil) {
        self.label = label
        self.value = value
        self.tone = tone
    }
}

/// Stats side by side in equal columns, between two rules.
public struct StatRow: View {
    private let stats: [Stat]

    public init(_ stats: [Stat]) {
        self.stats = stats
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(stats.indices, id: \.self) { index in
                let stat = stats[index]
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.label)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textTertiary)
                    Text(stat.value)
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundStyle(color(of: stat.tone))
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay(alignment: .top) { rule }
        .overlay(alignment: .bottom) { rule }
    }

    private var rule: some View {
        Rectangle().fill(Theme.separator).frame(height: 0.5)
    }

    private func color(of tone: Stat.Tone?) -> Color {
        switch tone {
        case .success: Theme.success
        case .warning: Theme.warning
        case nil: Theme.text
        }
    }
}
