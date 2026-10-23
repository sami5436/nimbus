import Foundation

// Service seams. Core declares them; NimbusData and the app target implement them;
// NimbusUI consumes them through `AppDependencies`. Every implementation throws only `WeatherError`.

/// Fetches a live forecast. Implemented by `OpenMeteoWeatherService` (NimbusData).
public protocol WeatherService: Sendable {
    func forecast(for coordinate: Coordinate) async throws -> Forecast
}

/// Place search by name. Implemented by `OpenMeteoGeocodingService` (NimbusData).
/// Returns an empty array (not an error) when nothing matches.
public protocol GeocodingService: Sendable {
    func search(_ query: String) async throws -> [Place]
}

/// Last successful forecast per place id. Implemented by `FileForecastCache` (NimbusData).
public protocol ForecastCache: Sendable {
    func forecast(forPlaceID placeID: String) async -> Forecast?
    func store(_ forecast: Forecast, forPlaceID placeID: String) async
}

/// What view models talk to for forecasts. Enables stale-while-revalidate:
/// show `cachedForecast` instantly, then `refreshForecast`, keep the cached one if refresh fails.
/// Implemented by `LiveForecastRepository` (NimbusData) over `WeatherService` + `ForecastCache`.
public protocol ForecastRepository: Sendable {
    /// Never touches the network. Nil when nothing was ever fetched for this place.
    func cachedForecast(for place: Place) async -> Forecast?
    /// Fetches live data and writes it to the cache on success.
    func refreshForecast(for place: Place) async throws -> Forecast
}

/// The user's saved places, in display order. Implemented by `FileSavedPlacesStore` (NimbusData).
/// Never contains the current-location place; that one is resolved live.
public protocol SavedPlacesStore: Sendable {
    func loadPlaces() async throws -> [Place]
    func savePlaces(_ places: [Place]) async throws
}

/// Unit preferences. Implemented by `FilePreferencesStore` (NimbusData).
/// Returns `.default` when nothing is stored or the file is unreadable.
public protocol PreferencesStore: Sendable {
    func loadPreferences() async -> UnitPreferences
    func savePreferences(_ preferences: UnitPreferences) async
}

/// Device location, resolved to a named place with id `Place.currentLocationID`.
/// Implemented with CoreLocation in the app target only.
/// Throws `.locationPermissionDenied` or `.locationUnavailable`.
public protocol CurrentLocationProvider: Sendable {
    func currentPlace() async throws -> Place
}
