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
        VStack(spacing: 2) {
            Text(placeName)
                .font(.system(size: 30, weight: .regular))
            Text(formatter.temperature(current.temperatureC))
                .font(.system(size: 96, weight: .thin))
                .padding(.leading, 18) // balances the degree sign so the digits look centered
            Text(current.condition.displayName)
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.8))
            if let today {
                Text("H:\(formatter.temperature(today.highC))  L:\(formatter.temperature(today.lowC))")
                    .font(.title3.weight(.medium))
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.15), radius: 6, y: 1)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
