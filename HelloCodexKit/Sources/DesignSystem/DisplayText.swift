import Foundation

/// Numbers, durations, and dates as the app shows them. Dates follow the Mac's
/// region settings, including its 12- or 24-hour clock.
public enum DisplayText {
    /// The minus sign, not a hyphen.
    public static let minus = "\u{2212}"

    /// "54%".
    public static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    /// "+4 pts" or "−14 pts". Halves round away from zero, the same both ways.
    public static func signedPoints(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        return "\(rounded < 0 ? minus : "+")\(abs(rounded)) pts"
    }

    /// "4d 19h", or "5h 12m" within the last day; never negative.
    public static func duration(_ interval: TimeInterval) -> String {
        let minutes = Int(max(0, interval) / 60)
        let (days, hours) = (minutes / (24 * 60), minutes / 60 % 24)
        return days > 0 ? "\(days)d \(hours)h" : "\(hours)h \(minutes % 60)m"
    }

    /// The reset date and time, in the Mac's region format: "Fri 2 Oct, 09:00"
    /// in British English, "Fri, Oct 2, 9:00 AM" in US English.
    public static func dateTime(
        _ date: Date, locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        // Formatted as two parts, because the regional formats join a date and a
        // time with "at", and the design uses a comma.
        let style = style(locale, calendar)
        let day = date.formatted(style.weekday(.abbreviated).day().month(.abbreviated))
        return "\(day), \(date.formatted(style.hour().minute()))"
    }

    /// A day and time that's only an estimate, rounded to 10 minutes: "Wed 04:40"
    /// in British English, "Wed 4:40 AM" in US English.
    public static func estimatedTime(
        _ date: Date, locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let step: TimeInterval = 10 * 60
        let rounded = Date(
            timeIntervalSince1970: (date.timeIntervalSince1970 / step).rounded() * step)
        return rounded.formatted(style(locale, calendar).weekday(.abbreviated).hour().minute())
    }

    /// "Fri".
    public static func weekday(
        _ date: Date, locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        date.formatted(style(locale, calendar).weekday(.abbreviated))
    }

    private static func style(_ locale: Locale, _ calendar: Calendar) -> Date.FormatStyle {
        Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }
}
