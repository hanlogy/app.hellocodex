import Foundation

/// Numbers, durations, and dates as the app shows them. Dates are in British
/// English, as in the design: "Fri 2 Oct, 09:00".
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

    /// "Fri 2 Oct, 09:00".
    public static func dateTime(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.day, .month], from: date)
        let month = formatter("MMM", calendar).string(from: date)
        return "\(weekday(date, calendar: calendar)) \(components.day ?? 0) \(month), "
            + clockTime(date, calendar: calendar)
    }

    /// "Wed 04:40", rounded to 10 minutes, for times that are only estimates.
    public static func estimatedTime(_ date: Date, calendar: Calendar = .current) -> String {
        let step: TimeInterval = 10 * 60
        let rounded = Date(
            timeIntervalSince1970: (date.timeIntervalSince1970 / step).rounded() * step)
        return "\(weekday(rounded, calendar: calendar)) \(clockTime(rounded, calendar: calendar))"
    }

    /// "Fri".
    public static func weekday(_ date: Date, calendar: Calendar = .current) -> String {
        formatter("EEE", calendar).string(from: date)
    }

    /// "09:00".
    private static func clockTime(_ date: Date, calendar: Calendar) -> String {
        formatter("HH:mm", calendar).string(from: date)
    }

    private static func formatter(_ format: String, _ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter
    }
}
