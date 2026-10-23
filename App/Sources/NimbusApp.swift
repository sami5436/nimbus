import SwiftUI
import NimbusCore
import NimbusUI

@main
struct NimbusApp: App {
    // The UI demo test passes -NimbusSampleData to run offline with sample data.
    private let dependencies = ProcessInfo.processInfo.arguments.contains("-NimbusSampleData")
        ? AppDependencies.preview() : AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
