import Foundation
import NimbusCore

/// `ForecastRepository` over a live `WeatherService` and a `ForecastCache`.
/// Cache key is `Place.id`. A successful refresh is written to the cache before returning.
public struct LiveForecastRepository: ForecastRepository {
    private let service: any WeatherService
    private let cache: any ForecastCache

    public init(service: any WeatherService, cache: any ForecastCache) {
        self.service = service
        self.cache = cache
    }

    public func cachedForecast(for place: Place) async -> Forecast? {
        // STUB(feat/data)
        nil
    }

    public func refreshForecast(for place: Place) async throws -> Forecast {
        // STUB(feat/data)
        throw WeatherError.unknown("LiveForecastRepository not implemented")
    }
}
