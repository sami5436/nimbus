import Foundation
import Testing
import NimbusChecks
import NimbusCore
@testable import NimbusData

@Suite("OpenMeteo forecast DTO")
struct OpenMeteoForecastDTOTests {
    static let cupertino = Coordinate(latitude: 37.323, longitude: -122.032)
    static let fetchedAt = Date(timeIntervalSince1970: 1_792_729_000)

    func fixtureJSON() throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: Fixture.data("forecast_cupertino"))
        return try #require(object as? [String: Any])
    }

    func decode(_ json: [String: Any]) throws -> OpenMeteoForecastDTO {
        try JSONDecoder().decode(OpenMeteoForecastDTO.self, from: JSONSerialization.data(withJSONObject: json))
    }

    func mapped() throws -> Forecast {
        let dto = try JSONDecoder().decode(OpenMeteoForecastDTO.self, from: Fixture.data("forecast_cupertino"))
        return try dto.toForecast(requested: Self.cupertino, fetchedAt: Self.fetchedAt)
    }

    @Test func mapsShapeAndMetadata() throws {
        let forecast = try mapped()
        #expect(forecast.daily.count == 10)
        #expect(forecast.hourly.count == 240)
        #expect(forecast.timeZoneIdentifier == "America/Los_Angeles")
        #expect(forecast.coordinate == Self.cupertino)
        #expect(forecast.fetchedAt == Self.fetchedAt)
    }

    @Test func mapsCurrentConditions() throws {
        let current = try mapped().current
        #expect(current.time == Date(timeIntervalSince1970: 1_792_728_900))
        #expect(current.temperatureC == 14.7)
        #expect(current.apparentTemperatureC == 14.9)
        #expect(current.windGustsKmh == 15.1)
        #expect(current.pressureHPa == 1015)
        #expect(current.visibilityMeters == 16_000)
        #expect(current.condition == .overcast)
        #expect(!current.isDaylight)
    }

    @Test func mapsHourlyAndDailyEntries() throws {
        let forecast = try mapped()
        try #require(forecast.hourly.count > 8)
        let hour = forecast.hourly[0]
        #expect(hour.temperatureC == 14.9)
        #expect(hour.precipitationProbabilityPercent == 16)
        #expect(forecast.hourly[4].condition == .drizzle)
        #expect(forecast.hourly[8].isDaylight)

        let day = try #require(forecast.daily.first)
        #expect(day.condition == .drizzle)
        #expect(day.highC == 16.3)
        #expect(day.lowC == 13.1)
        #expect(day.precipitationSumMm == 3.5)
        #expect(day.sunrise == Date(timeIntervalSince1970: 1_792_678_981))
        #expect(day.uvIndexMax == 2.85)
    }

    @Test func optionalSeriesMayBeAbsent() throws {
        var json = try fixtureJSON()
        var current = try #require(json["current"] as? [String: Any])
        var hourly = try #require(json["hourly"] as? [String: Any])
        var daily = try #require(json["daily"] as? [String: Any])
        current["wind_gusts_10m"] = nil
        hourly["precipitation_probability"] = nil
        daily["uv_index_max"] = nil
        daily["precipitation_probability_max"] = nil
        json["current"] = current
        json["hourly"] = hourly
        json["daily"] = daily

        let forecast = try decode(json).toForecast(requested: Self.cupertino, fetchedAt: Self.fetchedAt)
        #expect(forecast.current.windGustsKmh == nil)
        #expect(forecast.hourly.allSatisfy { $0.precipitationProbabilityPercent == nil })
        #expect(forecast.daily.allSatisfy { $0.uvIndexMax == nil && $0.precipitationProbabilityPercent == nil })
    }

    @Test(arguments: [("hourly", "weather_code"), ("hourly", "is_day"), ("daily", "temperature_2m_max"), ("daily", "sunset")])
    func mismatchedArrayLengthsThrowDecoding(section: String, key: String) throws {
        var json = try fixtureJSON()
        var body = try #require(json[section] as? [String: Any])
        var series = try #require(body[key] as? [Any])
        series.removeLast()
        body[key] = series
        json[section] = body

        let dto = try decode(json)
        #expect(throws: WeatherError.decoding) {
            try dto.toForecast(requested: Self.cupertino, fetchedAt: Self.fetchedAt)
        }
    }

    @Test func malformedJSONFailsToDecode() throws {
        let data = try Fixture.data("malformed")
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OpenMeteoForecastDTO.self, from: data)
        }
    }
}

@Suite("OpenMeteo geocoding DTO")
struct OpenMeteoGeocodingDTOTests {
    @Test func mapsResultsToPlaces() throws {
        let dto = try JSONDecoder().decode(OpenMeteoGeocodingDTO.self, from: Fixture.data("geocoding_cupertino"))
        let places = dto.toPlaces()
        #expect(places.map(\.id) == ["5341145", "3742459"])
        let first = try #require(places.first)
        #expect(first.name == "Cupertino")
        #expect(first.region == "California")
        #expect(first.country == "United States")
        #expect(first.coordinate == Coordinate(latitude: 37.323, longitude: -122.03218))
        #expect(first.timeZoneIdentifier == "America/Los_Angeles")
    }

    @Test func missingResultsKeyMapsToEmpty() throws {
        let dto = try JSONDecoder().decode(OpenMeteoGeocodingDTO.self, from: Fixture.data("geocoding_empty"))
        #expect(dto.toPlaces().isEmpty)
    }
}
