import CoreLocation
import NimbusCore

/// Owns the `CLLocationManager` used for when-in-use authorization and turns each authorization
/// state into either success or a `WeatherError`.
@MainActor
final class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    static let shared = LocationAuthorizer()

    private let manager = CLLocationManager()
    private var waiters: [CheckedContinuation<CLAuthorizationStatus, Never>] = []

    private override init() {
        super.init()
        manager.delegate = self
    }

    /// Returns when location may be read. Prompts once if the user has not decided yet.
    /// - Throws: `.locationPermissionDenied` when denied, `.locationUnavailable` when restricted
    ///   (for example by parental controls, so the user cannot grant it) or still undecided.
    func ensureAuthorized() async throws {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                waiters.append(continuation)
                manager.requestWhenInUseAuthorization()
            }
        }
        switch status {
        case .denied: throw WeatherError.locationPermissionDenied
        case .restricted, .notDetermined: throw WeatherError.locationUnavailable
        default: return
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.resume(with: status) }
    }

    private func resume(with status: CLAuthorizationStatus) {
        // The delegate also fires with the current state when it is attached; wait for a decision.
        guard status != .notDetermined else { return }
        let pending = waiters
        waiters = []
        for waiter in pending { waiter.resume(returning: status) }
    }
}
