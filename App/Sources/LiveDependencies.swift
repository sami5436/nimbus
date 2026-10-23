import Foundation
import NimbusCore
import NimbusData

extension AppDependencies {
    /// The production composition root: Open-Meteo services, file-backed stores under
    /// Application Support/Nimbus, CoreLocation and the real clock.
    static func live() -> AppDependencies {
        let directory = storageDirectory()
        let repository = LiveForecastRepository(
            service: OpenMeteoWeatherService(),
            cache: FileForecastCache(directory: directory)
        )
        return AppDependencies(
            forecasts: repository,
            geocoding: OpenMeteoGeocodingService(),
            savedPlaces: FileSavedPlacesStore(directory: directory),
            preferences: FilePreferencesStore(directory: directory),
            currentLocation: CoreLocationProvider(),
            now: { Date() }
        )
    }

    /// Falls back to the temporary directory so a storage failure degrades to a session-only app
    /// instead of a crash at launch.
    private static func storageDirectory() -> URL {
        (try? StorageLocation.defaultDirectory())
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("Nimbus", isDirectory: true)
    }
}
