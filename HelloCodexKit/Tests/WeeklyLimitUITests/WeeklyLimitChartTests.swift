import AppKit
import SwiftUI
import Testing
import WeeklyLimit

@testable import WeeklyLimitUI

private let stockholm: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return calendar
}()

/// The week from Fri 25 Sep 09:00 to Fri 2 Oct 09:00.
private let week = Week(
    endingAt: stockholm.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: 9))!)

private let summary: WeeklySummary = {
    let midnights = (0..<7).map { week.startsAt.addingTimeInterval(Double(15 + 24 * $0) * 3600) }
    return WeeklySummary(
        percentLeft: 100, week: week, runs: [[ChartPoint(time: week.startsAt, percentLeft: 100)]],
        days: ([week.startsAt] + midnights).map { DayUsage(startsAt: $0, usedPercent: nil) },
        dayGroups: [], todayIndex: 0, versusEvenPace: 0, runsOutAt: nil,
        projectionEnd: ChartPoint(time: week.resetsAt, percentLeft: 100))
}()

/// Draws a view on white, at a display scale.
@MainActor
private func render(_ view: some View, scale: Double) throws -> NSBitmapImageRep {
    let host = NSHostingView(
        rootView:
            view
            .background(Color.white)
            .environment(\.calendar, stockholm)
            .environment(\.locale, Locale(identifier: "en_GB"))
            .environment(\.displayScale, scale))
    host.appearance = NSAppearance(named: .aqua)
    host.frame = CGRect(origin: .zero, size: host.fittingSize)
    host.layoutSubtreeIfNeeded()
    let bitmap = try #require(
        NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(host.bounds.width * scale),
            pixelsHigh: Int(host.bounds.height * scale), bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
            bitsPerPixel: 0))
    bitmap.size = host.bounds.size
    host.cacheDisplay(in: host.bounds, to: bitmap)
    return bitmap
}

@MainActor
struct WeeklyLimitChartTests {
    /// A hairline covers one row of pixels, on standard and Retina displays. A
    /// one-pixel line centred on a pixel boundary covers two rows at half
    /// strength and looks soft.
    @Test(arguments: [1.0, 2.0])
    func drawsTheGridLinesCrisp(scale: Double) throws {
        let bitmap = try render(WeeklyLimitChart(summary: summary).frame(width: 680), scale: scale)

        // A quarter of the way in, only the 50% grid line crosses the middle
        // of the plot.
        let x = Int(680 * scale / 4)
        let rows = Int(60 * scale)..<Int(140 * scale)
        let inked = rows.filter { (bitmap.colorAt(x: x, y: $0)?.brightnessComponent ?? 1) < 0.99 }

        #expect(inked.count == 1, "The 50% grid line covers the rows \(inked)")
    }

    /// Wherever the popover places the chart, which can be between pixels.
    @Test(arguments: [1.0, 2.0], [0.0, 0.25, 0.5, 0.75])
    func drawsTheCompactBaseLine(scale: Double, offset: Double) throws {
        let width = 268.0
        let bitmap = try render(
            VStack(spacing: 0) {
                Spacer().frame(height: 10 + offset)
                WeeklyLimitChart(summary: summary, variant: .compact)
                Spacer().frame(height: 10)
            }
            .frame(width: width), scale: scale)

        // Around the chart's bottom edge, where nothing else is drawn this far in.
        let bottom = (10 + offset + 64) * scale
        let rows = Int(bottom - 2 * scale)...Int(bottom + scale)
        let x = Int(width / 4 * scale)
        #expect(
            rows.contains { (bitmap.colorAt(x: x, y: $0)?.brightnessComponent ?? 1) < 0.95 },
            "No base line")
    }
}
