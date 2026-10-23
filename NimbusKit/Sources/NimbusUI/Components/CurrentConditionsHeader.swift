import SwiftUI
import NimbusCore

/// Place name, big temperature, condition, "H:72° L:55°". Feels-like lives in the detail tiles.
public struct CurrentConditionsHeader: View {
    private let placeName: String
    private let current: CurrentConditions
    private let today: DailyForecast?
    private let formatter: WeatherFormatter

    public init(placeName: String, current: CurrentConditions, today: DailyForecast?, formatter: WeatherFormatter) {
        self.placeName = placeName
        self.current = current
        self.today = today
        self.formatter = formatter
    }

    public var body: some View {
        // STUB(feat/core-domain)
        VStack {
            Text(placeName)
            Text(formatter.temperature(current.temperatureC))
        }
    }
}
