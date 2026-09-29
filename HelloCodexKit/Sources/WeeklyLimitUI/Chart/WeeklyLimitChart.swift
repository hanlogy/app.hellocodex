import Charts
import DesignSystem
import SwiftUI
import WeeklyLimit

/// Percent left over the week: the recorded readings, dashed where the app
/// wasn't running, an even pace, and the projection, with rules, a now marker,
/// day ticks, and a legend. The compact variant is only the lines, thinner.
public struct WeeklyLimitChart: View {
    private let summary: WeeklySummary
    private let variant: Variant

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    public init(summary: WeeklySummary, variant: Variant = .full) {
        self.summary = summary
        self.variant = variant
    }

    public var body: some View {
        let data = WeeklyLimitChartData(summary: summary, locale: locale, calendar: calendar)
        switch variant {
        case .full:
            VStack(alignment: .leading, spacing: 8) {
                plot(data)
                    .frame(height: 200)
                    .background(rules)
                ticks(data.ticks)
                legend(runsOut: data.runsOut)
                    .padding(.top, 4)
            }
        case .compact:
            plot(data)
                .frame(height: 64)
                .overlay(alignment: .bottom) {
                    Hairline(color: Theme.separatorStrong)
                }
        }
    }

    private var isFull: Bool { variant == .full }

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

    private func plot(_ data: WeeklyLimitChartData) -> some View {
        Chart {
            line(data.evenPace, id: "pace", style: evenPace)
                .foregroundStyle(Theme.pace)
            line(data.projection, id: "projection", style: dashed)
                .foregroundStyle(data.runsOut ? Theme.warning : Theme.success)
            if isFull {
                area(data)
            }
            ForEach(data.runs.indices, id: \.self) { index in
                line(data.runs[index], id: "run \(index)", style: recorded)
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(Theme.text)
            }
            ForEach(data.gaps.indices, id: \.self) { index in
                line(data.gaps[index], id: "gap \(index)", style: dashed)
                    .foregroundStyle(Theme.text)
            }
            if isFull, let latest = data.latest {
                RuleMark(x: .value("Time", latest.time))
                    .lineStyle(StrokeStyle(lineWidth: 1))
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
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }

    private func line(_ points: [ChartPoint], id: String, style: StrokeStyle) -> some ChartContent {
        ForEach(points.indices, id: \.self) { index in
            LineMark(
                x: .value("Time", points[index].time),
                y: .value("Left", points[index].percentLeft),
                series: .value("Line", id)
            )
            .lineStyle(style)
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

    /// Rules at 100%, 50%, and 0% left, with the top two labelled.
    private var rules: some View {
        GeometryReader { proxy in
            let middle = proxy.size.height / 2
            ZStack(alignment: .topLeading) {
                Hairline(color: Theme.separator)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: middle))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: middle))
                }
                .stroke(Theme.grid, style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                Hairline(color: Theme.separatorStrong)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                axisLabel("100%").offset(y: 4)
                axisLabel("50%").offset(y: middle + 4)
            }
        }
    }

    private func axisLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, design: .monospaced))
            .foregroundStyle(Theme.textQuaternary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func ticks(_ ticks: [WeeklyLimitChartData.Tick]) -> some View {
        GeometryReader { proxy in
            ForEach(ticks, id: \.time) { tick in
                Text(tick.label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(tick.isToday ? Theme.text : Theme.textTertiary)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.leading, 3)
                    .frame(height: 16)
                    .overlay(alignment: .leading) {
                        Hairline(.vertical, color: Theme.separatorStrong)
                    }
                    .offset(x: tick.fraction * proxy.size.width)
            }
        }
        .frame(height: 16)
    }

    private func legend(runsOut: Bool) -> some View {
        HStack(spacing: 18) {
            legendItem("Recorded", swatch: recorded, color: Theme.text)
            legendItem("App not running", swatch: dashed, color: Theme.text)
            legendItem("Even pace", swatch: evenPace, color: Theme.pace)
            legendItem(
                "Projection", swatch: dashed, color: runsOut ? Theme.warning : Theme.success)
        }
        .font(.system(size: 11.5))
        .foregroundStyle(Theme.textTertiary)
    }

    private func legendItem(_ label: String, swatch: StrokeStyle, color: Color) -> some View {
        HStack(spacing: 6) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 14, y: 0))
            }
            .stroke(color, style: swatch)
            .frame(width: 14, height: swatch.lineWidth)
            Text(label)
        }
    }
}
