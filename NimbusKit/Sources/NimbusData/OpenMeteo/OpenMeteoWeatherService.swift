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
        // STUB(feat/data): build URL, fetch, decode DTO, map to Forecast.
        throw WeatherError.unknown("OpenMeteoWeatherService not implemented")
    }
}
