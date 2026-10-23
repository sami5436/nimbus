import SwiftUI
import NimbusCore

/// Two-column grid of square tiles: UV index, sunrise/sunset, wind, precipitation,
/// feels like, humidity, visibility, pressure.
public struct DetailTilesGrid: View {
    private let forecast: Forecast
    private let now: Date
    private let formatter: WeatherFormatter

    public init(forecast: Forecast, now: Date, formatter: WeatherFormatter) {
        self.forecast = forecast
        self.now = now
        self.formatter = formatter
    }

    public var body: some View {
        // STUB(feat/core-domain)
        Text("Details")
    }
}
