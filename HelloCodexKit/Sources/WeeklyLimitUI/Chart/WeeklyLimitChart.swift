import Charts
import DesignSystem
import SwiftUI
import WeeklyLimit

/// Percent left over the week: the recorded readings, dashed where the app
/// wasn't running, an even pace, and the projection, with a now marker, axes,
/// and a legend. The compact variant is only the lines, thinner, on a base
/// line.
public struct WeeklyLimitChart: View {
    private let summary: WeeklySummary
    private let variant: Variant

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.displayScale) private var displayScale

    public init(summary: WeeklySummary, variant: Variant = .full) {
        self.summary = summary
        self.variant = variant
    }

    public var body: some View {
        let data = WeeklyLimitChartData(summary: summary, locale: locale, calendar: calendar)
        Chart {
            line(data.evenPace, series: "pace", as: .evenPace)
            line(data.projection, series: "projection", as: .projection)
            if isFull {
                area(data)
            }
            ForEach(data.runs.indices, id: \.self) { index in
                line(data.runs[index], series: "run \(index)", as: .recorded)
                    .interpolationMethod(.stepEnd)
            }
            ForEach(data.gaps.indices, id: \.self) { index in
                line(data.gaps[index], series: "gap \(index)", as: .notRunning)
            }
            if isFull, let latest = data.latest {
                RuleMark(x: .value("Time", latest.time))
                    .lineStyle(hairline)
                    .foregroundStyle(Theme.separatorStrong)
                PointMark(x: .value("Time", latest.time), y: .value("Left", latest.percentLeft))
                    .symbol {
                        Circle()
                            .fill(Theme.text)
                            .frame(width: 9, height: 9)
                            .padding(3)
                            .background(Circle().fill(Theme.background))
                    }
            }
        }
        .chartXScale(domain: data.week.startsAt...data.week.resetsAt)
        .chartYScale(domain: 0...100)
        .chartForegroundStyleScale([
            Line.recorded.label: Theme.text,
            Line.notRunning.label: Theme.text,
            Line.evenPace.label: Theme.pace,
            Line.projection.label: data.runsOut ? Theme.warning : Theme.success,
        ])
        .chartLineStyleScale([
            Line.recorded.label: recorded,
            Line.notRunning.label: dashed,
            Line.evenPace.label: evenPace,
            Line.projection.label: dashed,
        ])
        .chartPlotStyle { plot in
            plot.frame(height: isFull ? 200 : 64)
        }
        .chartXAxis {
            if isFull {
                AxisMarks(values: data.ticks.map(\.time)) { value in
                    AxisTick(stroke: hairline)
                    AxisValueLabel(anchor: .topLeading) {
                        if let tick = data.ticks.first(where: { $0.time == value.as(Date.self) }) {
                            Text(tick.label)
                                .foregroundStyle(tick.isToday ? Theme.text : Theme.textTertiary)
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: isFull ? [0, 50, 100] : [0]) { value in
                // Centred in a row of pixels, not on the boundary between two,
                // so the line is crisp.
                AxisGridLine(stroke: hairline)
                    .offset(y: 0.5 / displayScale)
                if isFull, let percent = value.as(Double.self) {
                    AxisValueLabel(DisplayText.percent(percent))
                }
            }
        }
        .chartLegend(isFull ? .visible : .hidden)
        .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
    }

    /// The lines, as the legend names them.
    private enum Line {
        case recorded, notRunning, evenPace, projection

        var label: String {
            switch self {
            case .recorded: "Recorded"
            case .notRunning: "App not running"
            case .evenPace: "Even pace"
            case .projection: "Projection"
            }
        }
    }

    private var isFull: Bool { variant == .full }

    /// One pixel wide, on any display.
    private var hairline: StrokeStyle { StrokeStyle(lineWidth: 1 / displayScale) }

    // Line styles, thinner with shorter dashes in the compact variant.
    private var recorded: StrokeStyle { StrokeStyle(lineWidth: isFull ? 1.75 : 1.5) }
    private var dashed: StrokeStyle {
        isFull
            ? StrokeStyle(lineWidth: 1.5, dash: [2, 3])
            : StrokeStyle(lineWidth: 1.25, dash: [2, 2])
    }
    private var evenPace: StrokeStyle {
        StrokeStyle(lineWidth: 1, dash: isFull ? [3, 4] : [3, 3])
    }

    private func line(_ points: [ChartPoint], series: String, as line: Line) -> some ChartContent {
        ForEach(points.indices, id: \.self) { index in
            LineMark(
                x: .value("Time", points[index].time),
                y: .value("Left", points[index].percentLeft),
                series: .value("Line", series)
            )
            .foregroundStyle(by: .value("Kind", line.label))
            .lineStyle(by: .value("Kind", line.label))
        }
    }

    /// The area under the recorded line: steps within runs, straight across
    /// the gaps.
    private func area(_ data: WeeklyLimitChartData) -> some ChartContent {
        let parts =
            data.runs.enumerated().map { ("run area \($0.offset)", $0.element, true) }
            + data.gaps.enumerated().map { ("gap area \($0.offset)", $0.element, false) }
        return ForEach(parts, id: \.0) { id, points, isRun in
            ForEach(points.indices, id: \.self) { index in
                AreaMark(
                    x: .value("Time", points[index].time),
                    y: .value("Left", points[index].percentLeft),
                    series: .value("Area", id),
                    stacking: .unstacked
                )
                .interpolationMethod(isRun ? .stepEnd : .linear)
                .foregroundStyle(Theme.chartArea)
            }
        }
    }
}
