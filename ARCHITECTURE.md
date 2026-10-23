# Nimbus architecture

## Context
Nimbus is an Apple Weather style iOS app: current conditions, a 24 hour strip, a 10 day forecast with temperature range bars, detail tiles, saved locations with search, current location, condition-aware sky gradients, unit toggles, and solid loading, error, offline and empty states. Data comes from Open-Meteo (free, no key). v1 favors depth over breadth.

The dev machine has Command Line Tools only (no Xcode). `swift build` works, `swift test` and iOS builds do not. The design keeps nearly all code in a SwiftPM package that builds and is checkable on macOS, and keeps the iOS app target thin.

## Layout
```
project.yml                 XcodeGen spec for the iOS app target "Nimbus"
App/Sources/                @main, live wiring, CoreLocationProvider (iOS app target only)
NimbusKit/Package.swift     package "NimbusKit", product "NimbusKit" (Core + Data + UI)
NimbusKit/Sources/
  NimbusCore/               Models/, Services/, Logic/, Fakes/
  NimbusData/               HTTP/, OpenMeteo/, Persistence/, Repository/
  NimbusUI/                 Components/, ViewModels/, Screens/
  NimbusChecks/             check harness, suites, Fixtures/ (JSON)
  NimbusSelfCheck/          main.swift: runs all suites, exits 1 on failure
NimbusKit/Tests/NimbusKitTests/   Swift Testing wrapper over the same suites (Xcode only)
scripts/presubmit.sh, scripts/typecheck-app.sh
```

## Modules and dependency rules
```
            App (iOS target)
           /       |        \
   NimbusData   NimbusUI   CoreLocation
           \       /
          NimbusCore          NimbusChecks -> Core, Data, UI (checks only)
```
- **NimbusCore**: Foundation only. Sendable model structs, service protocols, `WeatherError`, pure logic (conversions, formatting, range bars, color scale, day/night, sky themes, forecast queries), fakes and deterministic preview data.
- **NimbusData**: implements the Core protocols with Open-Meteo and the file system. Never imports SwiftUI.
- **NimbusUI**: SwiftUI. Talks to services only through `AppDependencies` (Core protocols). Never imports NimbusData. Enforced by `Package.swift`.
- **App**: the composition root. Builds live `AppDependencies` and hands it to `RootView`. Owns CoreLocation because the package must not.
- Inside NimbusUI: `Components/` are stateless views taking plain values (no view models). `Screens/` compose components and own view models. Components never import screens.

## Data flow
```
RootView(dependencies)
  -> LocationsViewModel: savedPlaces.loadPlaces(), currentLocation?.currentPlace(), geocoding.search()
  -> WeatherViewModel(place) per page:
       1. forecasts.cachedForecast(place)  -> show immediately (state: loaded, stale)
       2. forecasts.refreshForecast(place) -> show fresh (state: loaded, live)
          on WeatherError.offline with cache -> keep cached + offline banner
          on error without cache            -> failed state with retry
  -> SettingsModel: preferences.load/save -> WeatherFormatter(preferences)
LiveForecastRepository = OpenMeteoWeatherService + FileForecastCache (write on success)
```
All model values are canonical metric (C, km/h, mm, m, hPa). Only `WeatherFormatter` converts, so cached data is unit-independent and toggling units is instant.

## Public interfaces (skeleton contracts)
Core (`NimbusCore/Services/Services.swift`):
```swift
protocol WeatherService: Sendable        { func forecast(for: Coordinate) async throws -> Forecast }
protocol GeocodingService: Sendable      { func search(_ query: String) async throws -> [Place] }
protocol ForecastCache: Sendable         { forecast(forPlaceID:) async -> Forecast?; store(_:forPlaceID:) async }
protocol ForecastRepository: Sendable    { cachedForecast(for: Place) async -> Forecast?
                                           refreshForecast(for: Place) async throws -> Forecast }
protocol SavedPlacesStore: Sendable      { loadPlaces() async throws -> [Place]; savePlaces(_:) async throws }
protocol PreferencesStore: Sendable      { loadPreferences() async -> UnitPreferences; savePreferences(_:) async }
protocol CurrentLocationProvider: Sendable { func currentPlace() async throws -> Place }
struct AppDependencies: Sendable         { forecasts, geocoding, savedPlaces, preferences, currentLocation?, now }
```
Models: `Coordinate`, `Place` (id = geocoding id or `Place.currentLocationID`), `Forecast` (current, hourly, daily, timeZoneIdentifier, fetchedAt), `CurrentConditions`, `HourlyForecast`, `DailyForecast`, `WeatherCondition` (WMO buckets), `UnitPreferences`, `PaletteColor`, `WeatherError` (offline, server, decoding, locationPermissionDenied, locationUnavailable, unknown).

Logic (bodies are stubs marked `STUB(feat/core-domain)`): `UnitConversion`, `WeatherFormatter`, `TemperatureRangeBar.layout(low:high:weekLow:weekHigh:current:) -> RangeBarLayout`, `TemperatureColorScale`, `DayPhase.isDaylight`, `SkyTheme(condition:isDaylight:)`, `Forecast.hours(from:count:)`, `.day(containing:)`, `.temperatureSpan`, `.isDaylight(at:)`.

Data: `HTTPClient`, `URLSessionHTTPClient`, `OpenMeteoWeatherService(client:baseURL:)`, `OpenMeteoGeocodingService(client:baseURL:)`, `FileForecastCache(directory:)`, `FileSavedPlacesStore(directory:)`, `FilePreferencesStore(directory:)`, `StorageLocation.defaultDirectory()`, `LiveForecastRepository(service:cache:)`.

UI components: `SkyBackground(theme:)`, `CurrentConditionsHeader(placeName:current:today:formatter:)`, `HourlyForecastStrip(hours:timeZone:now:formatter:)`, `DailyForecastList(days:timeZone:now:currentTemperatureC:formatter:)`, `TemperatureRangeBarView(low:high:weekLow:weekHigh:current:)`, `DetailTilesGrid(forecast:now:formatter:)`, `Color(_ palette: PaletteColor)`. Screen entry: `RootView(dependencies:)`.

Units may add public API inside files they own. Changing an existing signature above is a contract change: separate small PR through the lead.

## Open-Meteo contract
Forecast (metric defaults, unix timestamps, location-local days):
```
https://api.open-meteo.com/v1/forecast?latitude=37.323&longitude=-122.0322
 &current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,pressure_msl,visibility,precipitation,uv_index
 &hourly=temperature_2m,weather_code,is_day,precipitation_probability
 &daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max
 &timezone=auto&timeformat=unixtime&forecast_days=10
```
Geocoding: `https://geocoding-api.open-meteo.com/v1/search?name=<q>&count=10&language=en&format=json`. When nothing matches, the body has no `results` key (treat as `[]`). Verified against the live API on 2026-10-22.

## Concurrency model
Swift 6 language mode, complete checking. Models are `Sendable` structs. Stateful services are actors (file stores, caches, fakes). View models are `@MainActor @Observable final class`. Services cross into the main actor only via `await`. The check harness runs on the main actor.

## Testing approach
- `NimbusChecks` holds one suite per unit (`ContractChecks`, `CoreChecks`, `DataChecks`, `UIChecks`) built on a tiny `Checker`. The same suites run in two places: `swift run NimbusSelfCheck` (works with Command Line Tools) and `Tests/NimbusKitTests` under Swift Testing (needs Xcode). `swift build` never compiles test targets, so the test target stays inert here.
- Data checks are offline: Open-Meteo JSON fixtures in `NimbusChecks/Fixtures/` plus a stub `HTTPClient`.
- View model checks use the fakes in `NimbusCore/Fakes` and an injected clock (`AppDependencies.now`).
- Visual checks: `Snapshot.render(view, name:)` renders SwiftUI offscreen with `ImageRenderer` on macOS. Set `NIMBUS_SNAPSHOT_DIR` to write PNGs for review.
- App target: `scripts/typecheck-app.sh` type-checks `App/Sources` against the macOS SDK and built package modules.

## Presubmit
`./scripts/presubmit.sh` runs: `swift build`, `NimbusSelfCheck` (all suites), app typecheck, em dash scan, and `swift test` when Xcode is present. It must exit 0 before a PR. Once Xcode is installed, add `xcodegen generate && xcodebuild -scheme Nimbus -destination 'generic/platform=iOS Simulator' build`.

## Work units
Each unit branches from the skeleton on `main`, owns its files exclusively, and must leave presubmit green.

| Unit | Branch | Owns | Depends on |
|---|---|---|---|
| 1 Core domain + components | `feat/core-domain` | `NimbusCore/Models/WeatherCondition.swift`, `NimbusCore/Logic/**`, `NimbusUI/Components/**`, `NimbusChecks/CoreChecks.swift` | skeleton |
| 2 Data layer | `feat/data` | `NimbusData/**`, `NimbusChecks/DataChecks.swift`, `NimbusChecks/Fixtures/**` | skeleton |
| 3 View models + screens | `feat/screens` | `NimbusUI/ViewModels/**`, `NimbusUI/Screens/**`, `NimbusChecks/UIChecks.swift` | skeleton |
| 4 App shell | `feat/app-shell` | `App/**`, `project.yml` | 2, 3 (1 for visuals) |

Units 1 to 3 run in parallel. They meet only through the skeleton contracts. Details and acceptance checks: `~/Brain/Docs/2026-10-22-nimbus-architecture.md`.
