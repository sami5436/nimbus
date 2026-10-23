import Foundation
import NimbusCore

/// `WeatherService` backed by https://api.open-meteo.com/v1/forecast (no API key).
/// Requests metric units, `timezone=auto`, `timeformat=unixtime`, `forecast_days=10`.
public struct OpenMeteoWeatherService: WeatherService {
    private let client: any HTTPClient
    private let baseURL: URL

    public init(
        client: any HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = URL(string: "https://api.open-meteo.com/v1/forecast")!
    ) {
        self.client = client
        self.baseURL = baseURL
    }

    public func forecast(for coordinate: Coordinate) async throws -> Forecast {
        let dto = try await OpenMeteoHTTP.fetch(
            OpenMeteoForecastDTO.self, from: Self.url(for: coordinate, baseURL: baseURL), using: client)
        return try dto.toForecast(requested: coordinate, fetchedAt: Date())
    }

    /// The request URL for `coordinate`. Exposed for checks.
    public static func url(
        for coordinate: Coordinate,
        baseURL: URL = URL(string: "https://api.open-meteo.com/v1/forecast")!
    ) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: [
                "temperature_2m", "apparent_temperature", "relative_humidity_2m", "is_day", "weather_code",
                "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m", "pressure_msl", "visibility",
                "precipitation", "uv_index",
            ].joined(separator: ",")),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,is_day,precipitation_probability"),
            URLQueryItem(name: "daily", value: [
                "weather_code", "temperature_2m_max", "temperature_2m_min", "sunrise", "sunset",
                "uv_index_max", "precipitation_sum", "precipitation_probability_max",
            ].joined(separator: ",")),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "forecast_days", value: "10"),
        ]
        return components.url!
    }
}
