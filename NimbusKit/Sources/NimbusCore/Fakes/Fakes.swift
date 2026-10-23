import Foundation

// In-memory test doubles for every Core service. Used by NimbusChecks, the test target and SwiftUI previews.
// Actors where state mutates, so they are Sendable under Swift 6 strict concurrency.

public struct FakeWeatherService: WeatherService {
    public var result: Result<Forecast, WeatherError>

    public init(result: Result<Forecast, WeatherError> = .success(.preview)) {
        self.result = result
    }

    public func forecast(for coordinate: Coordinate) async throws -> Forecast {
        try result.get()
    }
}

public struct FakeGeocodingService: GeocodingService {
    public var result: Result<[Place], WeatherError>

    public init(result: Result<[Place], WeatherError> = .success(Place.previewSearchResults)) {
        self.result = result
    }

    public func search(_ query: String) async throws -> [Place] {
        try result.get()
    }
}

public actor InMemoryForecastCache: ForecastCache {
    public private(set) var storage: [String: Forecast]

    public init(storage: [String: Forecast] = [:]) {
        self.storage = storage
    }

    public func forecast(forPlaceID placeID: String) async -> Forecast? {
        storage[placeID]
    }

    public func store(_ forecast: Forecast, forPlaceID placeID: String) async {
        storage[placeID] = forecast
    }
}

/// Scriptable repository: set `cached` and `refreshResult` per test.
public actor FakeForecastRepository: ForecastRepository {
    public var cached: [String: Forecast]
    public var refreshResult: Result<Forecast, WeatherError>
    public private(set) var refreshCount = 0

    public init(
        cached: [String: Forecast] = [:],
        refreshResult: Result<Forecast, WeatherError> = .success(.preview)
    ) {
        self.cached = cached
        self.refreshResult = refreshResult
    }

    public func setRefreshResult(_ result: Result<Forecast, WeatherError>) {
        refreshResult = result
    }

    public func setCached(_ forecast: Forecast?, forPlaceID placeID: String) {
        cached[placeID] = forecast
    }

    public func cachedForecast(for place: Place) async -> Forecast? {
        cached[place.id]
    }

    public func refreshForecast(for place: Place) async throws -> Forecast {
        refreshCount += 1
        let forecast = try refreshResult.get()
        cached[place.id] = forecast
        return forecast
    }
}

public actor InMemorySavedPlacesStore: SavedPlacesStore {
    public private(set) var places: [Place]
    public var failure: WeatherError?

    public init(places: [Place] = [], failure: WeatherError? = nil) {
        self.places = places
        self.failure = failure
    }

    public func loadPlaces() async throws -> [Place] {
        if let failure { throw failure }
        return places
    }

    public func savePlaces(_ places: [Place]) async throws {
        if let failure { throw failure }
        self.places = places
    }
}

public actor InMemoryPreferencesStore: PreferencesStore {
    public private(set) var preferences: UnitPreferences

    public init(preferences: UnitPreferences = .default) {
        self.preferences = preferences
    }

    public func loadPreferences() async -> UnitPreferences {
        preferences
    }

    public func savePreferences(_ preferences: UnitPreferences) async {
        self.preferences = preferences
    }
}

public struct FakeCurrentLocationProvider: CurrentLocationProvider {
    public var result: Result<Place, WeatherError>

    public init(result: Result<Place, WeatherError> = .success(.previewCurrentLocation)) {
        self.result = result
    }

    public func currentPlace() async throws -> Place {
        try result.get()
    }
}

extension AppDependencies {
    /// Fully faked dependencies with one saved place and a cached preview forecast.
    public static func preview(
        places: [Place] = [.previewCupertino],
        forecasts: FakeForecastRepository = FakeForecastRepository(cached: [Place.previewCupertino.id: .preview]),
        now: @escaping @Sendable () -> Date = { Forecast.previewReferenceDate }
    ) -> AppDependencies {
        AppDependencies(
            forecasts: forecasts,
            geocoding: FakeGeocodingService(),
            savedPlaces: InMemorySavedPlacesStore(places: places),
            preferences: InMemoryPreferencesStore(),
            currentLocation: FakeCurrentLocationProvider(),
            now: now
        )
    }
}
