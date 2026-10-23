import CoreLocation
import Foundation
import NimbusCore

/// `CurrentLocationProvider` backed by CoreLocation. App target only: the package never imports CoreLocation.
/// Throws `.locationPermissionDenied` or `.locationUnavailable` (restricted, timed out, cancelled).
struct CoreLocationProvider: CurrentLocationProvider {
    /// Bounds the whole flow, authorization prompt included, so an unanswered prompt cannot hang callers.
    var timeout: Duration = .seconds(30)

    func currentPlace() async throws -> Place {
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
        let timeout = timeout
        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask {
                try await LocationAuthorizer.shared.ensureAuthorized()
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
