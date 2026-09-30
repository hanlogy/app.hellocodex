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

/// Stats side by side in equal columns between two rules, or in the compact
/// variant one per line, with the label on the left and the value on the right.
public struct StatRow: View {
    private let stats: [Stat]
    private let variant: Variant

    public init(_ stats: [Stat], variant: Variant = .full) {
        self.stats = stats
        self.variant = variant
    }

    public var body: some View {
        switch variant {
        case .full: columns
        case .compact: lines
        }
    }

    private var columns: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(stats.indices, id: \.self) { index in
                let stat = stats[index]
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.label)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textTertiary)
                    Text(stat.value)
                        .font(.system(size: 17, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(color(of: stat.tone))
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay(alignment: .top) { Divider() }
        .overlay(alignment: .bottom) { Divider() }
    }

    private var lines: some View {
        VStack(spacing: 8) {
            ForEach(stats.indices, id: \.self) { index in
                let stat = stats[index]
                HStack {
                    Text(stat.label)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(stat.value)
                        .font(.system(size: 12))
                        .monospacedDigit()
                        .foregroundStyle(color(of: stat.tone))
                }
            }
        }
        .font(.system(size: 12))
        .lineLimit(1)
    }

    private func color(of tone: Stat.Tone?) -> Color {
        switch tone {
        case .success: Theme.success
        case .warning: Theme.warning
        case nil: Theme.text
        }
    }
}
