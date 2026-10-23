import Foundation

extension Forecast {
    /// Up to `count` hourly entries starting with the hour that contains `date`.
    public func hours(from date: Date, count: Int = 24) -> [HourlyForecast] {
        let start = hourly.firstIndex { $0.time.addingTimeInterval(3600) > date } ?? hourly.endIndex
        return Array(hourly[start...].prefix(max(count, 0)))
    }

    /// The daily entry whose local day (in `timeZone`) contains `date`.
    public func day(containing date: Date) -> DailyForecast? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return daily.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// Min of daily lows and max of daily highs across `daily`, for range-bar scaling. Nil if empty.
    public var temperatureSpan: ClosedRange<Double>? {
        guard let low = daily.map(\.lowC).min(), let high = daily.map(\.highC).max() else { return nil }
        return low...max(low, high)
    }

    /// Day/night at `date` from that day's sunrise and sunset, falling back to `current.isDaylight`.
    public func isDaylight(at date: Date) -> Bool {
        let today = day(containing: date)
        return DayPhase.isDaylight(
            at: date, sunrise: today?.sunrise, sunset: today?.sunset, fallback: current.isDaylight)
    }
}
