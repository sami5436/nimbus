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
        await cache.forecast(forPlaceID: place.id)
    }

    public func refreshForecast(for place: Place) async throws -> Forecast {
        let forecast: Forecast
        do {
            forecast = try await service.forecast(for: place.coordinate)
        } catch {
            throw WeatherError.wrap(error)
        }
        await cache.store(forecast, forPlaceID: place.id)
        return forecast
    }
}
