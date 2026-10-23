import CoreLocation
import NimbusCore

/// Resolves when-in-use authorization, prompting once if the user has not decided yet.
@MainActor
final class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Returns when location may be read. Throws `locationPermissionDenied` when denied or restricted.
    func ensureAuthorized() async throws {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                pending = continuation
                manager.requestWhenInUseAuthorization()
            }
        }
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        default:
            throw WeatherError.locationPermissionDenied
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            // The delegate also fires on assignment with the undecided status; wait for the user's answer.
            guard status != .notDetermined, let pending else { return }
            self.pending = nil
            pending.resume(returning: status)
        }
    }
}
