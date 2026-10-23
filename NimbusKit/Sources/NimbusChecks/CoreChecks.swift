import Foundation
import SwiftUI
import NimbusCore
import NimbusUI

/// Owned by feat/core-domain.
@MainActor
public enum CoreChecks {
    public static func run(_ c: inout Checker) async {
        wmoTable(&c)
        conversions(&c)
        formatting(&c)
        rangeBars(&c)
        colorScale(&c)
        dayPhase(&c)
        skyThemes(&c)
        forecastQueries(&c)
        defaults(&c)
        snapshots(&c)
    }

    private static let us = WeatherFormatter(
        preferences: UnitPreferences(temperature: .fahrenheit, speed: .milesPerHour),
        locale: Locale(identifier: "en_US"))
    private static let metric = WeatherFormatter(
        preferences: UnitPreferences(temperature: .celsius, speed: .kilometersPerHour),
        locale: Locale(identifier: "en_US"))

    private static func wmoTable(_ c: inout Checker) {
        let codes = [0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99]
        for code in codes {
            c.expect(WeatherCondition(wmoCode: code) != .unknown, "WMO \(code) maps to a known case")
        }
        for code in [-1, 4, 10, 44, 100, 1000] {
            c.expectEqual(WeatherCondition(wmoCode: code), .unknown, "WMO \(code)")
        }
        c.expectEqual(WeatherCondition(wmoCode: 65), .heavyRain)
        c.expectEqual(WeatherCondition(wmoCode: 99), .thunderstormWithHail)
        for condition in WeatherCondition.allCases {
            c.expect(!condition.symbolName(isDaylight: true).isEmpty, "\(condition) day symbol")
            c.expect(!condition.symbolName(isDaylight: false).isEmpty, "\(condition) night symbol")
            c.expect(!condition.displayName.isEmpty, "\(condition) display name")
        }
        c.expect(
            WeatherCondition.clear.symbolName(isDaylight: true) != WeatherCondition.clear.symbolName(isDaylight: false),
            "clear has distinct night symbol")
    }

    private static func conversions(_ c: inout Checker) {
        c.expectClose(UnitConversion.temperature(celsius: 0, to: .fahrenheit), 32)
        c.expectClose(UnitConversion.temperature(celsius: 100, to: .fahrenheit), 212)
        c.expectClose(UnitConversion.temperature(celsius: -40, to: .fahrenheit), -40)
        c.expectClose(UnitConversion.temperature(celsius: 21.5, to: .celsius), 21.5)
        c.expectClose(UnitConversion.speed(kmh: 100, to: .milesPerHour), 62.137, tolerance: 0.001)
        c.expectClose(UnitConversion.speed(kmh: 100, to: .kilometersPerHour), 100)
        c.expectClose(UnitConversion.visibility(meters: 1609.344, imperial: true), 1)
        c.expectClose(UnitConversion.visibility(meters: 16_000, imperial: false), 16)
        c.expectClose(UnitConversion.precipitation(mm: 25.4, imperial: true), 1)
        c.expectClose(UnitConversion.precipitation(mm: 25.4, imperial: false), 25.4)
        c.expectClose(UnitConversion.pressure(hPa: 1013.25, imperial: true), 29.92, tolerance: 0.01)
        c.expectClose(UnitConversion.pressure(hPa: 1013.25, imperial: false), 1013.25)
    }

    private static func formatting(_ c: inout Checker) {
        c.expectEqual(us.temperature(22), "72°")
        c.expectEqual(us.temperatureWithUnit(22), "72°F")
        c.expectEqual(metric.temperature(21.6), "22°")
        c.expectEqual(metric.temperatureWithUnit(21.6), "22°C")
        c.expectEqual(metric.temperature(-0.4), "0°", "no negative zero")
        c.expectEqual(us.temperature(-17.9), "0°", "-17.9C is 0F")
        c.expectEqual(metric.temperature(-5.6), "-6°")
        c.expectEqual(us.windSpeed(19), "12 mph")
        c.expectEqual(metric.windSpeed(19.4), "19 km/h")
        c.expectEqual(us.visibility(16_000), "10 mi")
        c.expectEqual(metric.visibility(16_000), "16 km")
        c.expectEqual(us.precipitation(4.2), "0.2 in")
        c.expectEqual(metric.precipitation(4.2), "4 mm")
        c.expectEqual(us.pressure(1013.25), "29.92 inHg")
        c.expectEqual(metric.pressure(1013.25), "1013 hPa")
        c.expectEqual(us.percent(86.6), "87%")

        for (degrees, name) in [(0.0, "N"), (22.5, "NNE"), (359.0, "N"), (-90.0, "W"), (720.0, "N"),
                                (90.0, "E"), (180.0, "S"), (270.0, "W"), (315.0, "NW")] {
            c.expectEqual(us.compassDirection(degrees: degrees), name, "compass \(degrees)")
        }

        for (index, name) in [(0.0, "Low"), (2.0, "Low"), (3.0, "Moderate"), (5.0, "Moderate"), (6.0, "High"),
                              (7.0, "High"), (8.0, "Very High"), (10.0, "Very High"), (11.0, "Extreme"),
                              (14.0, "Extreme")] {
            c.expectEqual(us.uvCategory(index), name, "UV \(index)")
        }

        let la = TimeZone(identifier: "America/Los_Angeles")!
        let forecast = Forecast.preview
        let reference = Forecast.previewReferenceDate // 14:00 PDT
        c.expectEqual(us.hourLabel(reference, timeZone: la, isNow: false), "2PM")
        c.expectEqual(us.hourLabel(reference, timeZone: la, isNow: true), "Now")
        c.expectEqual(us.weekdayLabel(reference, timeZone: la, isToday: true), "Today")
        c.expectEqual(us.weekdayLabel(reference, timeZone: la, isToday: false), "Thu")
        c.expectEqual(us.clockTime(reference, timeZone: la), "2:00 PM")
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        c.expectEqual(us.clockTime(reference, timeZone: tokyo), "6:00 AM", "uses the forecast time zone")
        c.expectEqual(forecast.timeZone, la)
    }

    private static func rangeBars(_ c: inout Checker) {
        let interior = TemperatureRangeBar.layout(low: 10, high: 20, weekLow: 0, weekHigh: 40)
        c.expectClose(interior.start, 0.25)
        c.expectClose(interior.end, 0.5)
        c.expect(interior.marker == nil, "no marker without current")

        let withMarker = TemperatureRangeBar.layout(low: 10, high: 20, weekLow: 0, weekHigh: 40, current: 30)
        c.expectClose(withMarker.marker ?? -1, 0.75)

        let clamped = TemperatureRangeBar.layout(low: -10, high: 60, weekLow: 0, weekHigh: 40, current: 99)
        c.expectClose(clamped.start, 0)
        c.expectClose(clamped.end, 1)
        c.expectClose(clamped.marker ?? -1, 1)

        let point = TemperatureRangeBar.layout(low: 15, high: 15, weekLow: 0, weekHigh: 30)
        c.expectClose(point.start, 0.5)
        c.expectClose(point.end, 0.5)

        let flat = TemperatureRangeBar.layout(low: 10, high: 10, weekLow: 10, weekHigh: 10)
        c.expectClose(flat.start, 0)
        c.expectClose(flat.end, 1)

        let inverted = TemperatureRangeBar.layout(low: 30, high: 10, weekLow: 0, weekHigh: 40)
        c.expect(inverted.end >= inverted.start, "end never before start")

        for day in Forecast.preview.daily {
            let span = Forecast.preview.temperatureSpan!
            let layout = TemperatureRangeBar.layout(
                low: day.lowC, high: day.highC, weekLow: span.lowerBound, weekHigh: span.upperBound)
            c.expect(0...1 ~= layout.start && 0...1 ~= layout.end && layout.start <= layout.end, "preview layout valid")
        }
    }

    private static func colorScale(_ c: inout Checker) {
        let cold = TemperatureColorScale.color(celsius: -20)
        let mild = TemperatureColorScale.color(celsius: 18)
        let hot = TemperatureColorScale.color(celsius: 45)
        c.expect(cold.blue > hot.blue && hot.red > cold.red, "cold is bluer, hot is redder")
        c.expect(mild.green > cold.green && mild.green > hot.green, "mild leans green")
        c.expectEqual(TemperatureColorScale.color(celsius: -100), TemperatureColorScale.color(celsius: -10), "clamps cold")
        c.expectEqual(TemperatureColorScale.color(celsius: 100), TemperatureColorScale.color(celsius: 38), "clamps hot")
        var previousRed = -1.0
        var monotonic = true
        for celsius in stride(from: -10.0, through: 38.0, by: 4) {
            let red = TemperatureColorScale.color(celsius: celsius).red
            if red < previousRed - 0.2 { monotonic = false }
            previousRed = red
        }
        c.expect(monotonic, "ramp trends warmer")
        let gradient = TemperatureColorScale.gradient(fromCelsius: 5, toCelsius: 25)
        c.expect(gradient.count >= 2, "gradient has at least 2 stops")
        c.expectEqual(gradient.first, TemperatureColorScale.color(celsius: 5))
        c.expectEqual(gradient.last, TemperatureColorScale.color(celsius: 25))
        c.expect(TemperatureColorScale.gradient(fromCelsius: 10, toCelsius: 10).count >= 2, "equal ends still 2 stops")
    }

    private static func dayPhase(_ c: inout Checker) {
        let sunrise = Date(timeIntervalSince1970: 1_000_000)
        let sunset = sunrise.addingTimeInterval(12 * 3600)
        c.expect(DayPhase.isDaylight(at: sunrise, sunrise: sunrise, sunset: sunset, fallback: false), "sunrise is day")
        c.expect(!DayPhase.isDaylight(at: sunset, sunrise: sunrise, sunset: sunset, fallback: true), "sunset is night")
        c.expect(!DayPhase.isDaylight(at: sunrise.addingTimeInterval(-1), sunrise: sunrise, sunset: sunset, fallback: true))
        c.expect(DayPhase.isDaylight(at: sunrise.addingTimeInterval(3600), sunrise: sunrise, sunset: sunset, fallback: false))
        c.expect(DayPhase.isDaylight(at: sunrise, sunrise: nil, sunset: nil, fallback: true), "nil falls back true")
        c.expect(!DayPhase.isDaylight(at: sunrise, sunrise: nil, sunset: sunset, fallback: false), "nil falls back false")
    }

    private static func skyThemes(_ c: inout Checker) {
        for condition in WeatherCondition.allCases {
            let day = SkyTheme(condition: condition, isDaylight: true)
            let night = SkyTheme(condition: condition, isDaylight: false)
            c.expect(!day.isNight, "\(condition) day theme is not night")
            c.expect(night.isNight, "\(condition) night theme is night")
        }
        for theme in SkyTheme.allCases {
            c.expect(theme.gradient.count >= 2, "\(theme) gradient")
        }
        c.expectEqual(SkyTheme(condition: .thunderstorm, isDaylight: true), .stormDay)
        c.expectEqual(SkyTheme(condition: .snow, isDaylight: false), .snowNight)
        c.expectEqual(SkyTheme(condition: .rainShowers, isDaylight: true), .rainDay)
    }

    private static func forecastQueries(_ c: inout Checker) {
        let forecast = Forecast.preview
        let now = Forecast.previewReferenceDate
        let hours = forecast.hours(from: now)
        c.expectEqual(hours.count, 24)
        c.expectEqual(hours.first?.time, forecast.hourly[14].time, "starts at the hour containing now")
        c.expectEqual(forecast.hours(from: now.addingTimeInterval(1800)).first?.time, forecast.hourly[14].time)
        c.expectEqual(forecast.hours(from: now.addingTimeInterval(3600)).first?.time, forecast.hourly[15].time)
        c.expectEqual(forecast.hours(from: now, count: 5).count, 5)
        c.expectEqual(forecast.hours(from: now, count: 0).count, 0)
        c.expectEqual(forecast.hours(from: now.addingTimeInterval(-10 * 86_400)).first?.time, forecast.hourly[0].time,
                      "before the data starts at the first entry")
        c.expect(forecast.hours(from: now.addingTimeInterval(10 * 86_400)).isEmpty, "after the data is empty")

        c.expectEqual(forecast.day(containing: now)?.date, forecast.daily[0].date)
        let lateTonight = forecast.daily[0].date.addingTimeInterval(23 * 3600 + 30 * 60) // 23:30 local
        let justAfterMidnight = forecast.daily[1].date.addingTimeInterval(30 * 60) // 00:30 local
        c.expectEqual(forecast.day(containing: lateTonight)?.date, forecast.daily[0].date)
        c.expectEqual(forecast.day(containing: justAfterMidnight)?.date, forecast.daily[1].date)
        c.expect(forecast.day(containing: now.addingTimeInterval(60 * 86_400)) == nil, "outside range is nil")

        let span = forecast.temperatureSpan
        c.expectEqual(span?.lowerBound, forecast.daily.map(\.lowC).min())
        c.expectEqual(span?.upperBound, forecast.daily.map(\.highC).max())
        var empty = forecast
        empty.daily = []
        c.expect(empty.temperatureSpan == nil, "empty daily has no span")

        let today = forecast.daily[0]
        c.expect(forecast.isDaylight(at: today.sunrise!), "daylight at sunrise")
        c.expect(!forecast.isDaylight(at: today.sunset!), "night at sunset")
        c.expect(!forecast.isDaylight(at: today.date.addingTimeInterval(3600)), "night before dawn")
        var polar = forecast
        polar.daily = polar.daily.map { var d = $0; d.sunrise = nil; d.sunset = nil; return d }
        c.expectEqual(polar.isDaylight(at: now), forecast.current.isDaylight, "nil sun times use current")
    }

    private static func defaults(_ c: inout Checker) {
        let usPrefs = UnitPreferences(locale: Locale(identifier: "en_US"))
        c.expectEqual(usPrefs.temperature, .fahrenheit)
        c.expectEqual(usPrefs.speed, .milesPerHour)
        let metricPrefs = UnitPreferences(locale: Locale(identifier: "de_DE"))
        c.expectEqual(metricPrefs.temperature, .celsius)
        c.expectEqual(metricPrefs.speed, .kilometersPerHour)
        let ukPrefs = UnitPreferences(locale: Locale(identifier: "en_GB"))
        c.expectEqual(ukPrefs.temperature, .celsius)
        c.expectEqual(ukPrefs.speed, .milesPerHour)
    }

    private static func snapshots(_ c: inout Checker) {
        let forecast = Forecast.preview
        let now = Forecast.previewReferenceDate
        let formatter = us
        let zone = forecast.timeZone
        let theme = SkyTheme(condition: forecast.current.condition, isDaylight: forecast.isDaylight(at: now))
        let nightTheme = SkyTheme(condition: .rain, isDaylight: false)

        func card<V: View>(_ view: V, theme: SkyTheme = .clearDay) -> some View {
            ZStack(alignment: .top) {
                SkyBackground(theme: theme)
                view.padding(16)
            }
        }

        c.expect(Snapshot.render(SkyBackground(theme: theme), name: "sky-clear-day") != nil, "SkyBackground")
        c.expect(Snapshot.render(SkyBackground(theme: nightTheme), name: "sky-rain-night") != nil, "SkyBackground night")
        c.expect(Snapshot.render(
            card(CurrentConditionsHeader(
                placeName: "Cupertino", current: forecast.current,
                today: forecast.day(containing: now), formatter: formatter)),
            name: "header", size: CGSize(width: 390, height: 300)) != nil, "CurrentConditionsHeader")
        c.expect(Snapshot.render(
            card(HourlyForecastStrip(
                hours: forecast.hours(from: now), timeZone: zone, now: now, formatter: formatter)),
            name: "hourly", size: CGSize(width: 390, height: 200)) != nil, "HourlyForecastStrip")
        c.expect(Snapshot.render(
            card(DailyForecastList(
                days: forecast.daily, timeZone: zone, now: now,
                currentTemperatureC: forecast.current.temperatureC, formatter: formatter)),
            name: "daily", size: CGSize(width: 390, height: 640)) != nil, "DailyForecastList")
        c.expect(Snapshot.render(
            card(TemperatureRangeBarView(low: 10, high: 24, weekLow: 5, weekHigh: 30, current: 18)),
            name: "range-bar", size: CGSize(width: 300, height: 60)) != nil, "TemperatureRangeBarView")
        c.expect(Snapshot.render(
            card(DetailTilesGrid(forecast: forecast, now: now, formatter: formatter)),
            name: "tiles", size: CGSize(width: 390, height: 900)) != nil, "DetailTilesGrid")
        c.expect(Snapshot.render(
            card(DetailTilesGrid(forecast: forecast, now: now, formatter: metric), theme: nightTheme),
            name: "tiles-night-metric", size: CGSize(width: 390, height: 900)) != nil, "DetailTilesGrid night")
    }
}
