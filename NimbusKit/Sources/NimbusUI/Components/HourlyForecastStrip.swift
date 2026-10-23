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
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(title: "Hourly Forecast", symbol: "clock")
            Divider().overlay(Color.white.opacity(0.2))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                        column(hour, isNow: index == 0)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .weatherCard()
    }

    private func column(_ hour: HourlyForecast, isNow: Bool) -> some View {
        VStack(spacing: 8) {
            Text(formatter.hourLabel(hour.time, timeZone: timeZone, isNow: isNow))
                .font(.subheadline.weight(.medium))
            VStack(spacing: 1) {
                Image(systemName: hour.condition.symbolName(isDaylight: hour.isDaylight))
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                    .frame(height: 26)
                Text(chance(hour) ?? " ")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 1))
            }
            Text(formatter.temperature(hour.temperatureC))
                .font(.body.weight(.medium))
        }
        .foregroundStyle(.white)
        .frame(minWidth: 40)
        .accessibilityElement(children: .combine)
    }

    private func chance(_ hour: HourlyForecast) -> String? {
        guard let percent = hour.precipitationProbabilityPercent, percent >= 20 else { return nil }
        return "\(percent)%"
    }
}
