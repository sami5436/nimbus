import Foundation

/// Composition root contract. The app target builds the live instance; checks and previews use `.preview()`.
public struct AppDependencies: Sendable {
    public var forecasts: any ForecastRepository
    public var geocoding: any GeocodingService
    public var savedPlaces: any SavedPlacesStore
    public var preferences: any PreferencesStore
    /// Nil when the platform has no location support (previews, checks).
    public var currentLocation: (any CurrentLocationProvider)?
    /// Injected clock so day/night, "Now" labels and staleness are deterministic in checks.
    public var now: @Sendable () -> Date

    public init(
        forecasts: any ForecastRepository,
        geocoding: any GeocodingService,
        savedPlaces: any SavedPlacesStore,
        preferences: any PreferencesStore,
        currentLocation: (any CurrentLocationProvider)?,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.forecasts = forecasts
        self.geocoding = geocoding
        self.savedPlaces = savedPlaces
        self.preferences = preferences
        self.currentLocation = currentLocation
        self.now = now
    }
}
