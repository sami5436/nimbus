import Foundation

extension Forecast {
    /// Up to `count` hourly entries starting with the hour that contains `date`.
    public func hours(from date: Date, count: Int = 24) -> [HourlyForecast] {
        // STUB(feat/core-domain)
        Array(hourly.prefix(count))
    }

    /// The daily entry whose local day (in `timeZone`) contains `date`.
    public func day(containing date: Date) -> DailyForecast? {
        // STUB(feat/core-domain)
        daily.first
    }

    /// Min of daily lows and max of daily highs across `daily`, for range-bar scaling. Nil if empty.
    public var temperatureSpan: ClosedRange<Double>? {
        // STUB(feat/core-domain)
        nil
    }

    /// Day/night at `date` from that day's sunrise and sunset, falling back to `current.isDaylight`.
    public func isDaylight(at date: Date) -> Bool {
        // STUB(feat/core-domain)
        current.isDaylight
    }
}
