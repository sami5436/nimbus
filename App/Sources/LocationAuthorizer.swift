import CoreLocation
import NimbusCore

/// Owns the `CLLocationManager` used for when-in-use authorization and turns each authorization
/// state into either success or a `WeatherError`.
@MainActor
final class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    static let shared = LocationAuthorizer()

    private let manager: CLLocationManager
    private var waiters: [UUID: CheckedContinuation<CLAuthorizationStatus, Never>] = [:]

    private override convenience init() {
        self.init(manager: CLLocationManager())
    }

    /// Internal so tests can inject a manager whose status and prompt they control.
    init(manager: CLLocationManager) {
        self.manager = manager
        super.init()
        manager.delegate = self
    }

    /// Returns when location may be read. Prompts once if the user has not decided yet.
    /// Cancelling the task while the prompt is up stops the wait and throws `.locationUnavailable`.
    func ensureAuthorized() async throws {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            let id = UUID()
            status = await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    guard !Task.isCancelled else { return continuation.resume(returning: .notDetermined) }
                    waiters[id] = continuation
                    manager.requestWhenInUseAuthorization()
                }
            } onCancel: {
                Task { @MainActor in self.cancelWaiter(id) }
            }
        }
        if let error = Self.error(for: status) { throw error }
    }

    /// Nil when location may be read. Denied is `.locationPermissionDenied`. Restricted (the user
    /// cannot grant it, for example parental controls) and undecided are `.locationUnavailable`.
    nonisolated static func error(for status: CLAuthorizationStatus) -> WeatherError? {
        switch status {
        case .denied: .locationPermissionDenied
        case .restricted, .notDetermined: .locationUnavailable
        default: nil
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
        waiters = [:]
        for waiter in pending.values { waiter.resume(returning: status) }
    }

    private func cancelWaiter(_ id: UUID) {
        waiters.removeValue(forKey: id)?.resume(returning: .notDetermined)
    }
}
