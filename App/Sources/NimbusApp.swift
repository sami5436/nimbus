import SwiftUI
import NimbusCore
import NimbusUI

@main
struct NimbusApp: App {
    // The UI demo test passes -NimbusSampleData to run offline with sample data.
    private let dependencies = NimbusApp.makeDependencies()

    private static func makeDependencies() -> AppDependencies {
        let info = ProcessInfo.processInfo
        if info.arguments.contains("-NimbusSampleData") { return .preview() }
        var dependencies = AppDependencies.live()
        // Unit tests are hosted in the real app; never raise a system location prompt from them.
        if info.environment["XCTestConfigurationFilePath"] != nil {
            dependencies.currentLocation = UnavailableLocationProvider()
        }
        return dependencies
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}

/// Stands in for CoreLocation in hosted unit-test processes.
private struct UnavailableLocationProvider: CurrentLocationProvider {
    func currentPlace() async throws -> Place {
        throw WeatherError.locationUnavailable
    }
}
