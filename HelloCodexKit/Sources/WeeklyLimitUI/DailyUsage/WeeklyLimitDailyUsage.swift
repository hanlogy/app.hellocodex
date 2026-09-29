import DesignSystem
import SwiftUI
import WeeklyLimit

/// How much of the limit each day of the week used.
public struct WeeklyLimitDailyUsage: View {
    private let summary: WeeklySummary

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    public init(summary: WeeklySummary) {
        self.summary = summary
    }

    public var body: some View {
        let data = WeeklyLimitDailyUsageData(summary: summary, locale: locale, calendar: calendar)
        VStack(alignment: .leading, spacing: 12) {
            Text("Used per day")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            DayColumns(columns: data.columns, spacing: 8) {
                ForEach(data.bars, id: \.firstDay) { bar in
                    day(bar)
                        .layoutValue(key: DayColumns.Span.self, value: bar.span)
                }
            }
        }
    }

    private func day(_ bar: WeeklyLimitDailyUsageData.Bar) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Days that haven't started: a thin empty bar and a dash.
            RoundedRectangle(cornerRadius: 2)
                .fill(bar.height == nil ? Theme.barEmpty : bar.isToday ? Theme.text : Theme.bar)
                .frame(height: bar.height.map { $0 * 48 } ?? 2)
                .frame(height: 48, alignment: .bottom)
            Text(bar.value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(bar.height == nil ? Theme.textPlaceholder : Theme.text)
            Text(bar.label)
                .font(.system(size: 11))
                .foregroundStyle(bar.isToday ? Theme.text : Theme.textTertiary)
        }
        .lineLimit(1)
    }
}

/// Equal columns side by side, with each view spanning one or more of them.
private struct DayColumns: Layout {
    struct Span: LayoutValueKey {
        static let defaultValue = 1
    }

    let columns: Int
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let height =
            subviews.map { subview in
                subview.sizeThatFits(
                    ProposedViewSize(width: self.width(of: subview, in: width), height: nil)
                ).height
            }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        var x = bounds.minX
        for subview in subviews {
            let width = width(of: subview, in: bounds.width)
            // Aligned to the bottom, like the bars.
            subview.place(
                at: CGPoint(x: x, y: bounds.maxY), anchor: .bottomLeading,
                proposal: ProposedViewSize(width: width, height: nil))
            x += width + spacing
        }
    }

    private func width(of subview: LayoutSubview, in width: CGFloat) -> CGFloat {
        let column = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let span = CGFloat(subview[Span.self])
        return column * span + spacing * (span - 1)
    }
}
