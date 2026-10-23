import Foundation
import Testing
import NimbusCore

@Suite("WeatherFormatter")
struct WeatherFormatterTests {
    static let us = Locale(identifier: "en_US")
    static let de = Locale(identifier: "de_DE")
    static let imperial = UnitPreferences(temperature: .fahrenheit, speed: .milesPerHour)
    static let metric = UnitPreferences(temperature: .celsius, speed: .kilometersPerHour)

    // 2024-06-01 14:30 UTC, a Saturday.
    let date = Date(timeIntervalSince1970: 1_717_252_200)
    let utc = TimeZone(identifier: "UTC")!

    @Test(arguments: [(21.4, "21°"), (21.5, "22°"), (-0.4, "0°"), (-3.6, "-4°")])
    func temperatureRoundsAndNeverShowsNegativeZero(celsius: Double, expected: String) {
        let formatter = WeatherFormatter(preferences: Self.metric, locale: Self.us)
        #expect(formatter.temperature(celsius) == expected)
    }

    @Test func temperatureWithUnit() {
        #expect(WeatherFormatter(preferences: Self.imperial, locale: Self.us).temperatureWithUnit(22) == "72°F")
        #expect(WeatherFormatter(preferences: Self.metric, locale: Self.us).temperatureWithUnit(22) == "22°C")
    }

    @Test(arguments: [(0.0, "N"), (22.5, "NNE"), (90, "E"), (225, "SW"), (359, "N"), (-90, "W"), (450, "E")])
    func compassDirection(degrees: Double, expected: String) {
        let formatter = WeatherFormatter(preferences: Self.metric, locale: Self.us)
        #expect(formatter.compassDirection(degrees: degrees) == expected)
    }

    @Test(arguments: [(0.0, "Low"), (2.4, "Low"), (3, "Moderate"), (6, "High"), (8, "Very High"), (11, "Extreme")])
    func uvCategory(index: Double, expected: String) {
        let formatter = WeatherFormatter(preferences: Self.metric, locale: Self.us)
        #expect(formatter.uvCategory(index) == expected)
    }

    @Test func usEnglishMeasures() {
        let formatter = WeatherFormatter(preferences: Self.imperial, locale: Self.us)
        #expect(formatter.windSpeed(19.3) == "12 mph")
        #expect(formatter.visibility(16_093) == "10 mi")
        #expect(formatter.precipitation(5.08) == "0.2 in")
        #expect(formatter.pressure(1013.25) == "29.92 inHg")
    }

    @Test func germanMeasuresUseCommaDecimals() {
        let formatter = WeatherFormatter(preferences: Self.metric, locale: Self.de)
        #expect(formatter.windSpeed(19.3) == "19 km/h")
        #expect(formatter.visibility(500) == "0,5 km")
        #expect(formatter.precipitation(4) == "4 mm")
        #expect(formatter.pressure(1013) == "1013 hPa")
    }

    @Test func germanImperialStillUsesCommaDecimals() {
        let formatter = WeatherFormatter(preferences: Self.imperial, locale: Self.de)
        #expect(formatter.pressure(1013.25) == "29,92 inHg")
    }

    @Test func hourLabelInEnglishDropsSpaceBeforeMeridiem() {
        let formatter = WeatherFormatter(preferences: Self.metric, locale: Self.us)
        #expect(formatter.hourLabel(date, timeZone: utc, isNow: false) == "2PM")
        #expect(formatter.hourLabel(date, timeZone: utc, isNow: true) == "Now")
    }

    @Test func hourLabelInGermanUsesTwentyFourHourClock() {
        let formatter = WeatherFormatter(preferences: Self.metric, locale: Self.de)
        #expect(formatter.hourLabel(date, timeZone: utc, isNow: false).contains("14"))
    }

    @Test func clockTimeHonorsForecastTimeZone() throws {
        let formatter = WeatherFormatter(preferences: Self.metric, locale: Self.us)
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        #expect(formatter.clockTime(date, timeZone: utc) == "2:30 PM")
        #expect(formatter.clockTime(date, timeZone: tokyo) == "11:30 PM")
    }

    @Test func weekdayLabel() {
        let us = WeatherFormatter(preferences: Self.metric, locale: Self.us)
        let de = WeatherFormatter(preferences: Self.metric, locale: Self.de)
        #expect(us.weekdayLabel(date, timeZone: utc, isToday: true) == "Today")
        #expect(us.weekdayLabel(date, timeZone: utc, isToday: false) == "Sat")
        #expect(de.weekdayLabel(date, timeZone: utc, isToday: false) == "Sa")
    }
}
