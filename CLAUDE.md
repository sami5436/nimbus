# Nimbus

Apple Weather style iOS app. SwiftUI, Swift 6 strict concurrency, iOS 17+. Data from Open-Meteo (no key, no WeatherKit). Full design: `ARCHITECTURE.md`.

## Build and presubmit
- Presubmit (run before every PR, must exit 0): `./scripts/presubmit.sh`
  - `swift build --package-path NimbusKit`
  - `swift run --package-path NimbusKit NimbusSelfCheck` (suites: `contract core data ui`, pass names to run a subset)
  - `./scripts/typecheck-app.sh` (type-checks `App/Sources` against the macOS SDK)
  - em dash scan; `swift test` only when Xcode is installed
  - `NIMBUS_APP_TESTS=1 ./scripts/presubmit.sh` also runs the App tests (`xcodegen` + `xcodebuild test` on the iPhone 17 Pro simulator, override with `NIMBUS_SIM`); skips with a message if unavailable
- Visual check without Xcode: `NIMBUS_SNAPSHOT_DIR=$PWD/snapshots swift run --package-path NimbusKit NimbusSelfCheck`, then open the PNGs.
- Xcode project: `xcodegen generate` from `project.yml`. Never hand-edit `Nimbus.xcodeproj`.

## Module map
- `NimbusKit/Sources/NimbusCore`: models, service protocols, pure logic, fakes, preview data. Foundation only.
- `NimbusKit/Sources/NimbusData`: Open-Meteo clients, file persistence, `LiveForecastRepository`. Imports Core.
- `NimbusKit/Sources/NimbusUI`: `Components/` (reusable views), `ViewModels/` (`@Observable`), `Screens/`. Imports Core.
- `NimbusKit/Sources/NimbusChecks`: check suites + fixtures used by `NimbusSelfCheck` and `Tests/`.
- `App/Sources`: `@main`, live dependency wiring, CoreLocation. Nothing else.

## Rules
- Core imports nothing of ours. UI never imports Data. Only `App/` and `NimbusChecks` see every module.
- Model values are canonical metric (C, km/h, mm, m, hPa). Convert only in `WeatherFormatter`.
- Services are protocols in Core, throw only `WeatherError`, have fakes in `NimbusCore/Fakes`.
- Shared state: actors. View models: `@MainActor @Observable final class`. Models: `Sendable` structs.
- No `#Preview` macro (needs Xcode plugins); use `PreviewProvider` inside `#if DEBUG` if needed.
- Package code must build for macOS too: guard iOS-only modifiers with `#if os(iOS)`.
- Every behavior change adds checks to the owning suite in `NimbusChecks`.
- Shared contracts (`Models/` except `WeatherCondition.swift`, `Services/`, `Fakes/`, check harness, `Package.swift`, scripts) change only in their own small PR.
- No secrets, no em dashes.
