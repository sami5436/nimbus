import CoreLocation
import Foundation
import NimbusCore

/// `CurrentLocationProvider` backed by CoreLocation. App target only: the package never imports CoreLocation.
/// Permission denial maps to `locationPermissionDenied`; no fix in time maps to `locationUnavailable`.
struct CoreLocationProvider: CurrentLocationProvider {
    /// How long to wait for the first fix before giving up.
    var fixTimeout: Duration = .seconds(15)

    func currentPlace() async throws -> Place {
        try await LocationAuthorizer().ensureAuthorized()
        let location = try await firstFix()
        let resolved = await PlaceNameResolver.resolve(location)
        return Place(
            id: Place.currentLocationID,
            name: resolved.name,
            region: resolved.region,
            coordinate: Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
            timeZoneIdentifier: resolved.timeZoneIdentifier)
    }

    /// First usable location from `CLLocationUpdate.liveUpdates()`, racing a timeout.
    private func firstFix() async throws -> CLLocation {
        try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if #available(iOS 18, macOS 15, *), update.authorizationDenied || update.authorizationDeniedGlobally {
                        throw WeatherError.locationPermissionDenied
                    }
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
