import CoreLocation
import NimbusCore
import Testing
@testable import Nimbus

/// Manager whose status and prompt are scripted, so no system prompt is shown.
private final class FakeManager: CLLocationManager {
    nonisolated(unsafe) var status: CLAuthorizationStatus = .notDetermined
    nonisolated(unsafe) var promptCount = 0

    override var authorizationStatus: CLAuthorizationStatus { status }
    override func requestWhenInUseAuthorization() { promptCount += 1 }
}

@MainActor
struct LocationAuthorizerTests {
    private func waitForPrompt(_ manager: FakeManager) async {
        while manager.promptCount == 0 { await Task.yield() }
    }

    @Test func cancellingWhilePromptIsUpThrowsUnavailable() async {
        let manager = FakeManager()
        let authorizer = LocationAuthorizer(manager: manager)
        let task = Task { try await authorizer.ensureAuthorized() }
        await waitForPrompt(manager)
        task.cancel()
        await #expect(throws: WeatherError.locationUnavailable) { try await task.value }
    }

    @Test func cancellingBeforeTheWaiterIsRegisteredThrowsUnavailable() async {
        let manager = FakeManager()
        let authorizer = LocationAuthorizer(manager: manager)
        let task = Task { try await authorizer.ensureAuthorized() }
        task.cancel()
        await #expect(throws: WeatherError.locationUnavailable) { try await task.value }
    }

    @Test func decisionAfterPromptResumesWaiterOnce() async throws {
        let manager = FakeManager()
        let authorizer = LocationAuthorizer(manager: manager)
        let task = Task { try await authorizer.ensureAuthorized() }
        await waitForPrompt(manager)
        manager.status = .authorizedWhenInUse
        authorizer.locationManagerDidChangeAuthorization(manager)
        try await task.value
        // A late duplicate callback must not touch a spent continuation.
        authorizer.locationManagerDidChangeAuthorization(manager)
        await Task.yield()
    }
}
