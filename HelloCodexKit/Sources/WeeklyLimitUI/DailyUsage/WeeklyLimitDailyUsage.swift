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
            Grid(horizontalSpacing: 8, verticalSpacing: 0) {
                // One equal column per day.
                GridRow {
                    ForEach(0..<data.columns, id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                    }
                }
                GridRow(alignment: .bottom) {
                    ForEach(data.bars, id: \.firstDay) { bar in
                        day(bar)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .gridCellColumns(bar.span)
                    }
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
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(bar.height == nil ? Theme.textPlaceholder : Theme.text)
            Text(bar.label)
                .font(.system(size: 11))
                .foregroundStyle(bar.isToday ? Theme.text : Theme.textTertiary)
        }
        .lineLimit(1)
    }
}
