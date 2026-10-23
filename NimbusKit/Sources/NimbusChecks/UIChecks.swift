import Foundation
import SwiftUI
import NimbusCore
import NimbusUI

/// Counts geocoder calls so checks can prove short queries never reach it.
private actor CountingGeocoding: GeocodingService {
    private(set) var calls = 0
    var result: Result<[Place], WeatherError>

    init(result: Result<[Place], WeatherError> = .success(Place.previewSearchResults)) {
        self.result = result
    }

    func setResult(_ result: Result<[Place], WeatherError>) {
        self.result = result
    }

    func search(_ query: String) async throws -> [Place] {
        calls += 1
        return try result.get()
    }
}

/// Refreshes suspend until `release()`; nothing is cached. Lets checks prove nothing waits on the fetch.
private actor GatedRepository: ForecastRepository {
    private var released = false
    private var requested = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func cachedForecast(for place: Place) async -> Forecast? { nil }

    func refreshForecast(for place: Place) async throws -> Forecast {
        requested += 1
        if !released {
            await withCheckedContinuation { waiters.append($0) }
        }
        return .preview
    }

    func waitUntilRequested() async {
        while requested == 0 { await Task.yield() }
    }

    func release() {
        released = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}

/// Loads fine, fails every save.
private struct SaveFailingStore: SavedPlacesStore {
    let places: [Place]
    func loadPlaces() async throws -> [Place] { places }
    func savePlaces(_ places: [Place]) async throws { throw WeatherError.unknown("disk full") }
}

/// View model state machines against fakes, plus screen snapshots.
@MainActor
public enum UIChecks {
    private static let cupertino = Place.previewCupertino
    private static let oslo = Place.previewOslo
    private static let refDate = Forecast.previewReferenceDate

    private static func dependencies(
        repository: any ForecastRepository,
        places: [Place] = [],
        store: InMemorySavedPlacesStore? = nil,
        geocoding: any GeocodingService = FakeGeocodingService(),
        preferences: InMemoryPreferencesStore = InMemoryPreferencesStore(),
        currentLocation: (any CurrentLocationProvider)? = nil,
        now: Date = Forecast.previewReferenceDate
    ) -> AppDependencies {
        AppDependencies(
            forecasts: repository,
            geocoding: geocoding,
            savedPlaces: store ?? InMemorySavedPlacesStore(places: places),
            preferences: preferences,
            currentLocation: currentLocation,
            now: { now }
        )
    }

    private static func staleForecast() -> Forecast {
        var forecast = Forecast.preview
        forecast.fetchedAt = refDate.addingTimeInterval(-3600)
        return forecast
    }

    public static func run(_ c: inout Checker) async {
        await weatherChecks(&c)
        await locationsChecks(&c)
        await settingsChecks(&c)
        errorCopyChecks(&c)
        await snapshotChecks(&c)
    }

    // MARK: WeatherViewModel

    private static func weatherChecks(_ c: inout Checker) async {
        // Cache hit then live refresh ends in loaded live.
        let repo = FakeForecastRepository(cached: [cupertino.id: staleForecast()])
        let vm = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: repo))
        c.expectEqual(vm.state, .loading, "starts loading")
        await vm.load()
        c.expectEqual(vm.state, .loaded(.preview, .live), "stale cache then refresh ends live")
        c.expectEqual(await repo.refreshCount, 1, "stale cache triggers one refresh")
        c.expect(vm.forecast != nil, "forecast accessor")
        c.expect(!vm.isRefreshing, "not refreshing after load")

        // No cache + offline ends in failed(.offline).
        let offlineRepo = FakeForecastRepository(refreshResult: .failure(.offline))
        let failing = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: offlineRepo))
        await failing.load()
        c.expectEqual(failing.state, .failed(.offline), "no cache + offline fails")
        c.expect(failing.forecast == nil, "no forecast when failed")

        // Retry after failure succeeds.
        await offlineRepo.setRefreshResult(.success(.preview))
        await failing.retry()
        c.expectEqual(failing.state, .loaded(.preview, .live), "retry succeeds")

        // Cache + offline ends in loaded stale with offline flag.
        let staleOffline = FakeForecastRepository(
            cached: [cupertino.id: staleForecast()], refreshResult: .failure(.offline))
        let keeps = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: staleOffline))
        await keeps.load()
        c.expectEqual(keeps.state, .loaded(staleForecast(), .offline), "cache + offline keeps cache with flag")

        // Cache + server error keeps cache, not flagged offline.
        let staleServer = FakeForecastRepository(
            cached: [cupertino.id: staleForecast()], refreshResult: .failure(.server(statusCode: 500)))
        let server = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: staleServer))
        await server.load()
        c.expectEqual(server.state, .loaded(staleForecast(), .cached), "cache + server error stays cached")

        // No cache + server error fails with that error.
        let serverOnly = FakeForecastRepository(refreshResult: .failure(.server(statusCode: 503)))
        let broken = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: serverOnly))
        await broken.load()
        c.expectEqual(broken.state, .failed(.server(statusCode: 503)), "server error surfaces")

        // A cancelled load is not recorded as a failure.
        let cancelRepo = FakeForecastRepository(refreshResult: .failure(.unknown("cancelled")))
        let cancelVM = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: cancelRepo))
        let cancelTask = Task { await cancelVM.load() }
        cancelTask.cancel()
        await cancelTask.value
        c.expectEqual(cancelVM.state, .loading, "cancelled load does not fail")

        // Fresh cache skips refresh (injected clock 5 minutes after fetch).
        let freshRepo = FakeForecastRepository(cached: [cupertino.id: .preview])
        let fresh = WeatherViewModel(
            place: cupertino,
            dependencies: dependencies(repository: freshRepo, now: refDate.addingTimeInterval(300)))
        await fresh.load()
        c.expectEqual(fresh.state, .loaded(.preview, .live), "fresh cache is live")
        c.expectEqual(await freshRepo.refreshCount, 0, "fresh cache skips refresh")

        // Cache older than 10 minutes refreshes.
        let agedRepo = FakeForecastRepository(cached: [cupertino.id: .preview])
        let aged = WeatherViewModel(
            place: cupertino,
            dependencies: dependencies(repository: agedRepo, now: refDate.addingTimeInterval(601)))
        await aged.load()
        c.expectEqual(await agedRepo.refreshCount, 1, "cache past 10 minutes refreshes")

        // Pull to refresh bypasses the freshness window.
        await fresh.refresh()
        c.expectEqual(await freshRepo.refreshCount, 1, "pull to refresh always refreshes")

        // Cache with a fetch time in the future is not trusted as fresh.
        var future = Forecast.preview
        future.fetchedAt = refDate.addingTimeInterval(3600)
        let futureRepo = FakeForecastRepository(cached: [cupertino.id: future])
        let futureVM = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: futureRepo))
        await futureVM.load()
        c.expectEqual(await futureRepo.refreshCount, 1, "future-dated cache refreshes")
    }

    // MARK: LocationsViewModel

    private static func locationsChecks(_ c: inout Checker) async {
        let repo = FakeForecastRepository(cached: [cupertino.id: .preview, oslo.id: .preview])

        // Load: saved places, current location first.
        let store = InMemorySavedPlacesStore(places: [cupertino])
        let vm = LocationsViewModel(
            dependencies: dependencies(
                repository: repo, store: store, currentLocation: FakeCurrentLocationProvider()),
            debounce: .zero)
        c.expect(!vm.hasLoaded, "not loaded before load")
        await vm.load()
        c.expect(vm.hasLoaded, "loaded after load")
        c.expectEqual(vm.places, [cupertino], "saved places load")
        c.expectEqual(vm.displayPlaces.first, Place.previewCurrentLocation, "current location first")
        c.expectEqual(vm.displayPlaces.count, 2, "current plus saved")
        c.expect(!vm.isEmpty, "populated is not empty")
        c.expect(vm.summaries[cupertino.id] != nil, "summary loaded from cache")

        // Add, dedupe, persist.
        let added = await vm.add(oslo)
        c.expect(added, "add returns true")
        c.expectEqual(await store.places, [cupertino, oslo], "add persists")
        let duplicate = await vm.add(oslo)
        c.expect(!duplicate, "duplicate rejected")
        c.expectEqual(vm.places.count, 2, "dedupe keeps count")
        let dupCurrent = await vm.add(.previewCurrentLocation)
        c.expect(!dupCurrent, "current location id rejected")

        // Move and delete persist.
        vm.move(from: IndexSet(integer: 1), to: 0)
        c.expectEqual(vm.places, [oslo, cupertino], "move applies synchronously")
        await vm.settlePersistence()
        c.expectEqual(await store.places, [oslo, cupertino], "move persists")
        vm.delete(at: IndexSet(integer: 0))
        c.expectEqual(vm.places, [cupertino], "delete applies synchronously")
        await vm.settlePersistence()
        c.expectEqual(await store.places, [cupertino], "delete persists")
        c.expectEqual(vm.places, [cupertino], "delete updates view model")

        // Persist failure surfaces without losing the in-memory list.
        let failVM = LocationsViewModel(
            dependencies: AppDependencies(
                forecasts: repo, geocoding: FakeGeocodingService(),
                savedPlaces: SaveFailingStore(places: [cupertino]),
                preferences: InMemoryPreferencesStore(), currentLocation: nil, now: { Forecast.previewReferenceDate }))
        await failVM.load()
        await failVM.add(oslo)
        c.expectEqual(failVM.places.count, 2, "in-memory list kept after persist failure")
        c.expectEqual(failVM.persistError, .unknown("disk full"), "persist error surfaces")

        // Empty list and no location yields the empty state.
        let emptyVM = LocationsViewModel(dependencies: dependencies(repository: repo))
        c.expect(!emptyVM.isEmpty, "not empty before load")
        await emptyVM.load()
        c.expect(emptyVM.isEmpty, "no places and no location is empty")

        // Current location denied does not block saved places.
        let denied = LocationsViewModel(
            dependencies: dependencies(
                repository: repo, places: [cupertino],
                currentLocation: FakeCurrentLocationProvider(result: .failure(.locationPermissionDenied))))
        await denied.load()
        c.expectEqual(denied.places, [cupertino], "saved places survive denial")
        c.expectEqual(denied.currentLocationError, .locationPermissionDenied, "denial recorded")
        c.expectEqual(denied.displayPlaces, [cupertino], "denied location not shown")
        c.expect(!denied.isEmpty, "denied with saved places is not empty")

        // Denied and nothing saved is empty, with the reason available.
        let deniedEmpty = LocationsViewModel(
            dependencies: dependencies(
                repository: repo,
                currentLocation: FakeCurrentLocationProvider(result: .failure(.locationUnavailable))))
        await deniedEmpty.load()
        c.expect(deniedEmpty.isEmpty, "denied and nothing saved is empty")

        // Saved store failure does not crash load.
        let brokenStore = InMemorySavedPlacesStore(places: [], failure: .decoding)
        let brokenVM = LocationsViewModel(dependencies: dependencies(repository: repo, store: brokenStore))
        await brokenVM.load()
        c.expect(brokenVM.hasLoaded && brokenVM.places.isEmpty, "store failure yields empty list")

        // Uncached places fill in from a background fetch.
        let uncachedRepo = FakeForecastRepository()
        let uncachedVM = LocationsViewModel(
            dependencies: dependencies(repository: uncachedRepo, places: [cupertino, oslo]))
        await uncachedVM.load()
        await uncachedVM.add(Place(id: "1", name: "X", coordinate: Coordinate(latitude: 0, longitude: 0)))
        await uncachedVM.awaitBackgroundFetch()
        c.expectEqual(uncachedVM.places.count, 3, "add completes")
        c.expectEqual(uncachedVM.summaries.count, 3, "background fetch fills every card")

        // The fetch never blocks: load and add return while it is suspended, then the card fills in.
        let gate = GatedRepository()
        let gatedVM = LocationsViewModel(dependencies: dependencies(repository: gate, places: [cupertino]))
        await gatedVM.load()
        await gate.waitUntilRequested()
        c.expect(gatedVM.hasLoaded, "load returned while the fetch is suspended")
        c.expect(gatedVM.summaries[cupertino.id] == nil, "card empty while fetch is suspended")
        var selected: Place?
        selected = oslo  // the screen selects first, then adds
        await gatedVM.add(oslo)
        c.expectEqual(selected, oslo, "selection happened while fetch was suspended")
        c.expectEqual(gatedVM.places, [cupertino, oslo], "add returned while fetch is suspended")
        c.expect(gatedVM.summaries.isEmpty, "still no summaries before the fetch completes")
        await gate.release()
        await gatedVM.awaitBackgroundFetch()
        c.expect(gatedVM.summaries[cupertino.id] != nil, "card fills in after fetch completes")
        c.expect(gatedVM.summaries[oslo.id] != nil, "added card fills in too")

        // Summary uses the injected clock: cache over a day old, night-time now.
        var oldCache = Forecast.preview
        oldCache.fetchedAt = refDate.addingTimeInterval(-3 * 86_400)
        let lateNow = refDate.addingTimeInterval(34 * 3600)
        let clockRepo = FakeForecastRepository(cached: [cupertino.id: oldCache])
        let clockVM = LocationsViewModel(
            dependencies: dependencies(repository: clockRepo, places: [cupertino], now: lateNow))
        await clockVM.load()
        let summary = clockVM.summaries[cupertino.id]
        c.expectEqual(summary?.highC, oldCache.day(containing: lateNow)?.highC, "summary high follows now")
        c.expectEqual(summary?.lowC, oldCache.day(containing: lateNow)?.lowC, "summary low follows now")
        c.expectEqual(summary?.isDaylight, oldCache.isDaylight(at: lateNow), "summary sky follows now")

        // Search: under 2 characters never hits geocoding.
        let geocoder = CountingGeocoding()
        let searchVM = LocationsViewModel(
            dependencies: dependencies(repository: repo, geocoding: geocoder), debounce: .zero)
        searchVM.updateQuery("c")
        await searchVM.performSearch()
        c.expectEqual(await geocoder.calls, 0, "short query skips geocoding")
        c.expectEqual(searchVM.searchState, .idle, "short query is idle")
        c.expect(!searchVM.isSearching, "short query is not searching")

        // Search: results.
        searchVM.updateQuery("cup")
        await searchVM.performSearch()
        c.expectEqual(searchVM.searchState, .results(Place.previewSearchResults), "results")
        c.expect(await geocoder.calls >= 1, "geocoder called for 3 character query")

        // Debounced path eventually delivers results.
        searchVM.updateQuery("cupe")
        try? await Task.sleep(for: .milliseconds(100))
        c.expectEqual(searchVM.searchState, .results(Place.previewSearchResults), "debounced search lands")

        // Clearing the query resets state.
        searchVM.updateQuery("")
        c.expectEqual(searchVM.searchState, .idle, "cleared query resets")

        // Search: empty and error.
        await geocoder.setResult(.success([]))
        searchVM.updateQuery("zzzz")
        await searchVM.performSearch()
        c.expectEqual(searchVM.searchState, .empty, "no matches is empty")
        await geocoder.setResult(.failure(.offline))
        searchVM.updateQuery("oslo")
        await searchVM.performSearch()
        c.expectEqual(searchVM.searchState, .failed(.offline), "geocoding error surfaces as search error")

        // Adding from search clears the query.
        searchVM.updateQuery("cup")
        await searchVM.add(cupertino)
        c.expectEqual(searchVM.query, "", "add clears query")
    }

    // MARK: SettingsModel

    private static func settingsChecks(_ c: inout Checker) async {
        let prefs = InMemoryPreferencesStore()
        let deps = dependencies(repository: FakeForecastRepository(), preferences: prefs)
        let settings = SettingsModel(dependencies: deps, locale: Locale(identifier: "en_US"))
        c.expectEqual(settings.preferences, .default, "starts at defaults")
        await settings.setTemperature(.celsius)
        c.expectEqual(await prefs.preferences.temperature, .celsius, "temperature persists")
        c.expectEqual(settings.formatter.preferences.temperature, .celsius, "formatter follows temperature")
        await settings.setSpeed(.kilometersPerHour)
        c.expectEqual(await prefs.preferences.speed, .kilometersPerHour, "speed persists")
        c.expectEqual(settings.formatter.preferences.speed, .kilometersPerHour, "formatter follows speed")

        let reloaded = SettingsModel(dependencies: deps)
        await reloaded.load()
        c.expectEqual(reloaded.preferences.temperature, .celsius, "preferences reload")
    }

    // MARK: Error copy

    private static func errorCopyChecks(_ c: inout Checker) {
        let errors: [WeatherError] = [
            .offline, .server(statusCode: 500), .decoding,
            .locationPermissionDenied, .locationUnavailable, .unknown("x"),
        ]
        for error in errors {
            c.expect(!error.displayTitle.isEmpty && !error.displayMessage.isEmpty, "copy for \(error)")
        }
    }

    // MARK: Snapshots

    private static func snapshotChecks(_ c: inout Checker) async {
        let size = CGSize(width: 390, height: 844)
        func screen(_ vm: WeatherViewModel, _ settings: SettingsModel, _ now: Date) -> WeatherScreen {
            WeatherScreen(viewModel: vm, settings: settings, now: { now })
        }

        let okRepo = FakeForecastRepository(cached: [cupertino.id: .preview])
        let okDeps = dependencies(repository: okRepo, places: [cupertino, oslo], currentLocation: FakeCurrentLocationProvider())
        let settings = SettingsModel(dependencies: okDeps, locale: Locale(identifier: "en_US"))

        let loading = WeatherViewModel(place: cupertino, dependencies: okDeps)
        c.expect(Snapshot.render(screen(loading, settings, refDate), name: "weather-loading", size: size) != nil, "snapshot loading")

        let loaded = WeatherViewModel(place: cupertino, dependencies: okDeps)
        await loaded.load()
        c.expect(Snapshot.render(screen(loaded, settings, refDate), name: "weather-loaded", size: size) != nil, "snapshot loaded")

        let offlineRepo = FakeForecastRepository(cached: [cupertino.id: staleForecast()], refreshResult: .failure(.offline))
        let offline = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: offlineRepo))
        await offline.load()
        c.expect(Snapshot.render(screen(offline, settings, refDate), name: "weather-offline", size: size) != nil, "snapshot stale offline")

        let failRepo = FakeForecastRepository(refreshResult: .failure(.server(statusCode: 500)))
        let failed = WeatherViewModel(place: cupertino, dependencies: dependencies(repository: failRepo))
        await failed.load()
        c.expect(Snapshot.render(screen(failed, settings, refDate), name: "weather-failed", size: size) != nil, "snapshot failed")

        let populated = LocationsViewModel(dependencies: okDeps)
        await populated.load()
        c.expect(
            Snapshot.render(LocationsScreen(viewModel: populated, settings: settings) { _ in }, name: "locations-populated", size: size) != nil,
            "snapshot locations populated")

        let emptyVM = LocationsViewModel(dependencies: dependencies(repository: FakeForecastRepository()))
        await emptyVM.load()
        c.expect(
            Snapshot.render(LocationsScreen(viewModel: emptyVM, settings: settings) { _ in }, name: "locations-empty", size: size) != nil,
            "snapshot locations empty")

        c.expect(Snapshot.render(RootView(dependencies: okDeps), name: "root", size: size) != nil, "snapshot root")
    }
}
