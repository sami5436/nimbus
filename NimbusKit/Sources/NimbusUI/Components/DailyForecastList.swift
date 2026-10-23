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
        let weekLow = days.map(\.lowC).min() ?? 0
        let weekHigh = days.map(\.highC).max() ?? 0
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(title: "\(days.count)-Day Forecast", symbol: "calendar")
                .padding(.bottom, 8)
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                Divider().overlay(Color.white.opacity(0.2))
                row(day, weekLow: weekLow, weekHigh: weekHigh)
            }
        }
        .padding(14)
        .weatherCard()
    }

    private func row(_ day: DailyForecast, weekLow: Double, weekHigh: Double) -> some View {
        let isToday = isSameDay(day.date, now)
        return HStack(spacing: 10) {
            Text(formatter.weekdayLabel(day.date, timeZone: timeZone, isToday: isToday))
                .font(.body.weight(.medium))
                .frame(width: 56, alignment: .leading)
            VStack(spacing: 0) {
                Image(systemName: day.condition.symbolName(isDaylight: true))
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                if let chance = day.precipitationProbabilityPercent, chance >= 20 {
                    Text("\(chance)%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 1))
                }
            }
            .frame(width: 40, height: 40)
            Text(formatter.temperature(day.lowC))
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(width: 40, alignment: .trailing)
            TemperatureRangeBarView(
                low: day.lowC, high: day.highC, weekLow: weekLow, weekHigh: weekHigh,
                current: isToday ? currentTemperatureC : nil)
            Text(formatter.temperature(day.highC))
                .frame(width: 40, alignment: .leading)
        }
        .font(.body.weight(.medium))
        .foregroundStyle(.white)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(a, inSameDayAs: b)
    }
}
