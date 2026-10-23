import SwiftUI
import NimbusCore
import NimbusUI

@main
struct NimbusApp: App {
    // STUB(feat/app-shell): replace with live wiring (Open-Meteo services, file stores, CoreLocation).
    private let dependencies = AppDependencies.preview()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
