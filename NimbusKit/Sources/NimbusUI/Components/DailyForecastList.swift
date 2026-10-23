import SwiftUI
import NimbusCore

/// 10-day card: weekday, symbol (+ precip chance), low, `TemperatureRangeBarView`, high.
public struct DailyForecastList: View {
    private let days: [DailyForecast]
    private let timeZone: TimeZone
    private let now: Date
    private let currentTemperatureC: Double?
    private let formatter: WeatherFormatter

    /// `currentTemperatureC` draws the marker dot on today's bar.
    public init(
        days: [DailyForecast],
        timeZone: TimeZone,
        now: Date,
        currentTemperatureC: Double?,
        formatter: WeatherFormatter
    ) {
        self.days = days
        self.timeZone = timeZone
        self.now = now
        self.currentTemperatureC = currentTemperatureC
        self.formatter = formatter
    }

    public var body: some View {
        // STUB(feat/core-domain)
        Text("\(days.count) days")
    }
}
