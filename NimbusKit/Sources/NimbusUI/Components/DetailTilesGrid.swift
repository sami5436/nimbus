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
        let current = forecast.current
        let today = forecast.day(containing: now)
        let zone = forecast.timeZone
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            tile("UV Index", "sun.max.fill", value: String(Int(current.uvIndex.rounded())),
                 caption: formatter.uvCategory(current.uvIndex)) {
                UVGauge(index: current.uvIndex)
            }
            tile("Sunrise", "sunrise.fill",
                 value: today?.sunrise.map { formatter.clockTime($0, timeZone: zone) } ?? "--",
                 caption: today?.sunset.map { "Sunset: \(formatter.clockTime($0, timeZone: zone))" } ?? "") {
                SunArc(progress: sunProgress(today))
            }
            tile("Wind", "wind", value: formatter.windSpeed(current.windSpeedKmh),
                 caption: current.windGustsKmh.map { "Gusts \(formatter.windSpeed($0))" } ?? "") {
                WindCompass(degrees: current.windDirectionDegrees, label: formatter.compassDirection(degrees: current.windDirectionDegrees))
            }
            tile("Precipitation", "drop.fill", value: formatter.precipitation(today?.precipitationSumMm ?? current.precipitationMm),
                 caption: "Expected today") { EmptyView() }
            tile("Feels Like", "thermometer.medium", value: formatter.temperature(current.apparentTemperatureC),
                 caption: feelsLikeCaption(current)) { EmptyView() }
            tile("Humidity", "humidity.fill", value: formatter.percent(current.relativeHumidityPercent),
                 caption: "") { EmptyView() }
            tile("Visibility", "eye.fill", value: formatter.visibility(current.visibilityMeters),
                 caption: "") { EmptyView() }
            tile("Pressure", "gauge.medium", value: formatter.pressure(current.pressureHPa),
                 caption: "") { EmptyView() }
        }
    }

    private func tile<Visual: View>(
        _ title: String, _ symbol: String, value: String, caption: String,
        @ViewBuilder visual: () -> Visual
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CardHeader(title: title, symbol: symbol)
            Text(value)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Spacer(minLength: 0)
            visual()
            if !caption.isEmpty {
                Text(caption)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .aspectRatio(1, contentMode: .fit)
        .weatherCard()
        .accessibilityElement(children: .combine)
    }

    private func sunProgress(_ day: DailyForecast?) -> Double? {
        guard let rise = day?.sunrise, let set = day?.sunset, set > rise else { return nil }
        return min(max(now.timeIntervalSince(rise) / set.timeIntervalSince(rise), 0), 1)
    }

    private func feelsLikeCaption(_ current: CurrentConditions) -> String {
        let delta = current.apparentTemperatureC - current.temperatureC
        if abs(delta) < 1 { return "Similar to the actual temperature." }
        return delta < 0 ? "Wind is making it feel colder." : "Humidity is making it feel warmer."
    }
}

/// Green to purple scale with a dot at the current index (0...11).
private struct UVGauge: View {
    let index: Double

    var body: some View {
        GeometryReader { proxy in
            let x = min(max(index / 11, 0), 1) * proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(LinearGradient(
                    colors: [.green, .yellow, .orange, .red, .purple], startPoint: .leading, endPoint: .trailing))
                Circle().fill(.white).frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
                    .offset(x: min(max(x - 4, 0), proxy.size.width - 8))
            }
        }
        .frame(height: 5)
    }
}

/// Half-circle horizon with the sun dot at `progress` between sunrise and sunset.
private struct SunArc: View {
    let progress: Double?

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let radius = min(width / 2, height)
            let center = CGPoint(x: width / 2, y: height)
            ZStack {
                Path { path in
                    path.addArc(center: center, radius: radius, startAngle: .degrees(180),
                                endAngle: .degrees(0), clockwise: false)
                }
                .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                Path { path in
                    path.move(to: CGPoint(x: center.x - radius - 6, y: height))
                    path.addLine(to: CGPoint(x: center.x + radius + 6, y: height))
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                if let progress {
                    let angle = Double.pi * (1 + progress)
                    Circle().fill(Color.yellow).frame(width: 10, height: 10)
                        .shadow(color: .yellow.opacity(0.7), radius: 4)
                        .position(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                }
            }
        }
        .frame(height: 34)
    }
}

/// Dial with N/E/S/W ticks, an arrow showing where the wind blows toward, and the compass label.
private struct WindCompass: View {
    let degrees: Double
    let label: String

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            ForEach(0..<4, id: \.self) { tick in
                Capsule().fill(Color.white.opacity(0.6))
                    .frame(width: 1.5, height: 5)
                    .offset(y: -22)
                    .rotationEffect(.degrees(Double(tick) * 90))
            }
            Image(systemName: "location.north.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(degrees + 180))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .offset(y: 15)
        }
        .frame(width: 56, height: 56)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
