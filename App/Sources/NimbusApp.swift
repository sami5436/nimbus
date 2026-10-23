import SwiftUI
import NimbusCore
import NimbusData
import NimbusUI

@main
struct NimbusApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
