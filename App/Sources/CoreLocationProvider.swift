import CoreLocation
import Foundation
import NimbusCore

/// `CurrentLocationProvider` backed by CoreLocation. App target only: the package never imports CoreLocation.
/// Throws `.locationPermissionDenied` or `.locationUnavailable` (restricted, timed out, cancelled).
struct CoreLocationProvider: CurrentLocationProvider {
    /// Bounds the location fix only. The authorization prompt is excluded: the user may take as long as
    /// they like, and the wait ends on their decision or on task cancellation.
    var timeout: Duration = .seconds(30)

    func currentPlace() async throws -> Place {
        // Hosted tests launch the real app; never raise a system prompt from them.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            throw WeatherError.locationUnavailable
        }
        let location: CLLocation
        do {
            location = try await authorizedFix()
        } catch is CancellationError {
            throw WeatherError.locationUnavailable
        }
        let label = await ReverseGeocoder.label(for: location)
        return Place(
            id: Place.currentLocationID,
            name: label.name,
            country: label.country,
            coordinate: Coordinate(
                latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        )
    }

    private func authorizedFix() async throws -> CLLocation {
        try await LocationAuthorizer.shared.ensureAuthorized()
        let timeout = timeout
        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if let location = update.location { return location }
                }
                throw WeatherError.locationUnavailable
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw WeatherError.locationUnavailable
            }
            defer { group.cancelAll() }
            guard let location = try await group.next() else { throw WeatherError.locationUnavailable }
            return location
        }
    }
}
