import Foundation
import NimbusCore

/// `CurrentLocationProvider` backed by CoreLocation. App target only: the package never imports CoreLocation.
struct CoreLocationProvider: CurrentLocationProvider {
    func currentPlace() async throws -> Place {
        // STUB(feat/app-shell): request when-in-use authorization, read one fix, reverse geocode a name.
        throw WeatherError.locationUnavailable
    }
}
