import Foundation
import NimbusCore
import NimbusData

extension AppDependencies {
    /// Live wiring: Open-Meteo services, file-backed stores under Application Support, the real clock.
    /// Preferences and saved places persist in that directory. Falls back to a temporary directory
    /// if Application Support is unavailable, so the app still runs (without surviving relaunch).
    static func live() -> AppDependencies {
        let directory = (try? StorageLocation.defaultDirectory())
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("Nimbus", isDirectory: true)
        let repository = LiveForecastRepository(
            service: OpenMeteoWeatherService(),
            cache: FileForecastCache(directory: directory))
        return AppDependencies(
            forecasts: repository,
            geocoding: OpenMeteoGeocodingService(),
            savedPlaces: FileSavedPlacesStore(directory: directory),
            preferences: FilePreferencesStore(directory: directory),
            currentLocation: CoreLocationProvider(),
            now: { Date() })
    }
}
