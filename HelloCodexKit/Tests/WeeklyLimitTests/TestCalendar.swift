import Foundation

/// A calendar in a fixed time zone, so day boundaries don't depend on where the
/// tests run. Stockholm changes its clocks, which the daylight saving tests
/// need.
let stockholm: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
    return calendar
}()

/// A local time in Stockholm.
func local(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    stockholm.date(
        from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

extension TimeInterval {
    static func minutes(_ count: Double) -> TimeInterval { count * 60 }
    static func hours(_ count: Double) -> TimeInterval { count * 60 * 60 }
}
