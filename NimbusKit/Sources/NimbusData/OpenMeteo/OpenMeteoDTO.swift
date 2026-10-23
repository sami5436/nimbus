import Foundation
import NimbusCore

/// Wire format of the Open-Meteo forecast response (unixtime, metric). Internal to NimbusData.
struct OpenMeteoForecastDTO: Decodable {
    struct Current: Decodable {
        let time: TimeInterval
        let temperature_2m: Double
        let apparent_temperature: Double
        let relative_humidity_2m: Double
        let is_day: Int
        let weather_code: Int
        let wind_speed_10m: Double
        let wind_direction_10m: Double
        let wind_gusts_10m: Double?
        let pressure_msl: Double
        let visibility: Double
        let precipitation: Double
        let uv_index: Double
    }

    struct Hourly: Decodable {
        let time: [TimeInterval]
        let temperature_2m: [Double]
        let weather_code: [Int]
        let is_day: [Int]
        let precipitation_probability: [Double?]?
    }

    struct Daily: Decodable {
        let time: [TimeInterval]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let sunrise: [TimeInterval?]
        let sunset: [TimeInterval?]
        let uv_index_max: [Double?]?
        let precipitation_sum: [Double?]
        let precipitation_probability_max: [Double?]?
    }

    let timezone: String
    let current: Current
    let hourly: Hourly
    let daily: Daily

    /// Maps to the domain model. Throws `.decoding` when parallel arrays disagree in length.
    func toForecast(requested: Coordinate, fetchedAt: Date) throws -> Forecast {
        let hourCount = hourly.time.count
        guard hourly.temperature_2m.count == hourCount,
              hourly.weather_code.count == hourCount,
              hourly.is_day.count == hourCount else { throw WeatherError.decoding }

        let dayCount = daily.time.count
        guard daily.weather_code.count == dayCount,
              daily.temperature_2m_max.count == dayCount,
              daily.temperature_2m_min.count == dayCount,
              daily.sunrise.count == dayCount,
              daily.sunset.count == dayCount,
              daily.precipitation_sum.count == dayCount else { throw WeatherError.decoding }

        func date(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }
        func element<T>(_ values: [T?]?, _ index: Int) -> T? {
            guard let values, index < values.count else { return nil }
            return values[index]
        }

        let hours = (0..<hourCount).map { i in
            HourlyForecast(
                time: date(hourly.time[i]),
                temperatureC: hourly.temperature_2m[i],
                condition: WeatherCondition(wmoCode: hourly.weather_code[i]),
                isDaylight: hourly.is_day[i] == 1,
                precipitationProbabilityPercent: element(hourly.precipitation_probability, i).map { Int($0.rounded()) }
            )
        }
        let days = (0..<dayCount).map { i in
            DailyForecast(
                date: date(daily.time[i]),
                condition: WeatherCondition(wmoCode: daily.weather_code[i]),
                highC: daily.temperature_2m_max[i],
                lowC: daily.temperature_2m_min[i],
                precipitationSumMm: daily.precipitation_sum[i] ?? 0,
                precipitationProbabilityPercent: element(daily.precipitation_probability_max, i).map { Int($0.rounded()) },
                sunrise: daily.sunrise[i].map(date),
                sunset: daily.sunset[i].map(date),
                uvIndexMax: element(daily.uv_index_max, i)
            )
        }
        let now = CurrentConditions(
            time: date(current.time),
            temperatureC: current.temperature_2m,
            apparentTemperatureC: current.apparent_temperature,
            condition: WeatherCondition(wmoCode: current.weather_code),
            isDaylight: current.is_day == 1,
            relativeHumidityPercent: current.relative_humidity_2m,
            windSpeedKmh: current.wind_speed_10m,
            windDirectionDegrees: current.wind_direction_10m,
            windGustsKmh: current.wind_gusts_10m,
            pressureHPa: current.pressure_msl,
            visibilityMeters: current.visibility,
            precipitationMm: current.precipitation,
            uvIndex: current.uv_index
        )
        // Keep the requested coordinate: the API returns the snapped grid point, not the place.
        return Forecast(
            coordinate: requested,
            timeZoneIdentifier: timezone,
            fetchedAt: fetchedAt,
            current: now,
            hourly: hours,
            daily: days
        )
    }
}

struct OpenMeteoGeocodingDTO: Decodable {
    struct Result: Decodable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let timezone: String?
        let country: String?
        let admin1: String?
    }

    /// Absent when nothing matched.
    let results: [Result]?

    func toPlaces() -> [Place] {
        (results ?? []).map {
            Place(
                id: String($0.id),
                name: $0.name,
                region: $0.admin1,
                country: $0.country,
                coordinate: Coordinate(latitude: $0.latitude, longitude: $0.longitude),
                timeZoneIdentifier: $0.timezone
            )
        }
    }
}

enum OpenMeteoHTTP {
    /// Fetches `url`, enforces 2xx, decodes `T`. Throws only `WeatherError`.
    static func fetch<T: Decodable>(_ type: T.Type, from url: URL, using client: any HTTPClient) async throws -> T {
        let data: Data
        let status: Int
        do {
            (data, status) = try await client.get(url)
        } catch {
            throw WeatherError.wrap(error)
        }
        guard (200..<300).contains(status) else { throw WeatherError.server(statusCode: status) }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw WeatherError.decoding
        }
    }
}
