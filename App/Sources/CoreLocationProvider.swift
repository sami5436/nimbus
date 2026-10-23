import CoreLocation
import Foundation
import NimbusCore

/// `CurrentLocationProvider` backed by CoreLocation. App target only: the package never imports CoreLocation.
/// Throws `.locationPermissionDenied` or `.locationUnavailable` (restricted, no fix in time, lookup failure).
struct CoreLocationProvider: CurrentLocationProvider {
    /// How long to wait for a first fix before giving up.
    var fixTimeout: Duration = .seconds(10)

    func currentPlace() async throws -> Place {
        try await LocationAuthorizer.shared.ensureAuthorized()
        let location = try await firstFix()
        let label = await ReverseGeocoder.label(for: location)
        return Place(
            id: Place.currentLocationID,
            name: label.name,
            country: label.country,
            coordinate: Coordinate(
                latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        )
    }

    private func firstFix() async throws -> CLLocation {
        try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if let location = update.location { return location }
                }
                throw WeatherError.locationUnavailable
            }
            group.addTask {
                try await Task.sleep(for: fixTimeout)
                throw WeatherError.locationUnavailable
            }
            defer { group.cancelAll() }
            guard let location = try await group.next() else { throw WeatherError.locationUnavailable }
            return location
        }
    }
}
