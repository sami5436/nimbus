import SwiftUI
import NimbusCore

/// Horizontally scrolling card: hour label, SF Symbol, temperature. First item reads "Now".
public struct HourlyForecastStrip: View {
    private let hours: [HourlyForecast]
    private let timeZone: TimeZone
    private let now: Date
    private let formatter: WeatherFormatter

    /// `hours` is already sliced by the caller (`Forecast.hours(from:count:)`).
    public init(hours: [HourlyForecast], timeZone: TimeZone, now: Date, formatter: WeatherFormatter) {
        self.hours = hours
        self.timeZone = timeZone
        self.now = now
        self.formatter = formatter
    }

    public var body: some View {
        // STUB(feat/core-domain)
        Text("\(hours.count) hours")
    }
}
