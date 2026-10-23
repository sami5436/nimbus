// swift-tools-version: 6.0
// NimbusKit: all Nimbus logic and UI. The iOS app target (../App, ../project.yml) only wires it up.
import PackageDescription

let package = Package(
    name: "NimbusKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // One product for the app to link. It exposes three modules: NimbusCore, NimbusData, NimbusUI.
        .library(name: "NimbusKit", targets: ["NimbusCore", "NimbusData", "NimbusUI"]),
        .executable(name: "NimbusSelfCheck", targets: ["NimbusSelfCheck"]),
    ],
    targets: [
        // Models, service protocols, pure logic, fakes. Foundation only.
        .target(name: "NimbusCore"),
        // Open-Meteo client, on-disk persistence, ForecastRepository. Depends on Core only.
        .target(name: "NimbusData", dependencies: ["NimbusCore"]),
        // @Observable view models, SwiftUI components and screens. Depends on Core only.
        .target(name: "NimbusUI", dependencies: ["NimbusCore"]),
        // Check suites + JSON fixtures, shared by the self-check executable and the test target.
        .target(
            name: "NimbusChecks",
            dependencies: ["NimbusCore", "NimbusData", "NimbusUI"],
            resources: [.copy("Fixtures")]
        ),
        // Presubmit runner: `swift run NimbusSelfCheck`. Exits non-zero on any failed check.
        .executableTarget(name: "NimbusSelfCheck", dependencies: ["NimbusChecks"]),
        // Swift Testing wrapper over the same suites. `swift build` never compiles test targets,
        // so this stays inert until `swift test` is available (full Xcode install).
        .testTarget(name: "NimbusKitTests", dependencies: ["NimbusChecks"]),
    ],
    swiftLanguageModes: [.v6]
)
