import Foundation
import Observation
import NimbusCore

/// What a saved-locations card shows, taken from the cached forecast.
public struct PlaceSummary: Sendable, Hashable {
    public var temperatureC: Double
    public var highC: Double?
    public var lowC: Double?
    public var condition: WeatherCondition
    public var isDaylight: Bool
}

public enum SearchState: Sendable, Equatable {
    case idle
    case searching
    case results([Place])
    case empty
    case failed(WeatherError)
}

/// Saved places, the optional current location, and place search.
@MainActor
@Observable
public final class LocationsViewModel {
    /// Searches shorter than this never reach the geocoder.
    public static let minimumQueryLength = 2

    /// Saved places in display order. Never contains the current location.
    public private(set) var places: [Place] = []
    public private(set) var currentPlace: Place?
    /// Why the current location is unavailable, if it is. Saved places still work.
    public private(set) var currentLocationError: WeatherError?
    public private(set) var summaries: [String: PlaceSummary] = [:]
    public private(set) var hasLoaded = false
    public private(set) var isResolvingLocation = false
    public private(set) var persistError: WeatherError?

    public private(set) var query = ""
    public private(set) var searchState: SearchState = .idle

    private let dependencies: AppDependencies
    private let debounce: Duration
    private var searchTask: Task<Void, Never>?
    private var persistTask: Task<Void, Never>?

    public init(dependencies: AppDependencies, debounce: Duration = .milliseconds(300)) {
        self.dependencies = dependencies
        self.debounce = debounce
    }

    /// Current location first, then saved places.
    public var displayPlaces: [Place] {
        (currentPlace.map { [$0] } ?? []) + places
    }

    /// Nothing to show: no saved places and no current location (after everything resolved).
    public var isEmpty: Bool {
        hasLoaded && !isResolvingLocation && displayPlaces.isEmpty
    }

    public var isSearching: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).count >= Self.minimumQueryLength
    }

    // MARK: Loading

    public func load() async {
        do {
            places = try await dependencies.savedPlaces.loadPlaces()
        } catch {
            places = []
            persistError = WeatherError.wrap(error)
        }
        hasLoaded = true

        if let provider = dependencies.currentLocation {
            isResolvingLocation = true
            do {
                currentPlace = try await provider.currentPlace()
                currentLocationError = nil
            } catch {
                currentPlace = nil
                currentLocationError = WeatherError.wrap(error)
            }
            isResolvingLocation = false
        }
        await loadSummaries()
    }

    /// Fills `summaries` from the cache only. Never touches the network: places without a cache
    /// show a placeholder until their weather page loads, which avoids fetching the same place twice.
    /// Uses the injected clock so a day-old cache shows today's range and the right sky.
    public func loadSummaries() async {
        let now = dependencies.now()
        for place in displayPlaces {
            guard let forecast = await dependencies.forecasts.cachedForecast(for: place) else { continue }
            let today = forecast.day(containing: now)
            summaries[place.id] = PlaceSummary(
                temperatureC: forecast.current.temperatureC,
                highC: today?.highC,
                lowC: today?.lowC,
                condition: forecast.current.condition,
                isDaylight: forecast.isDaylight(at: now)
            )
        }
    }

    // MARK: Editing

    /// Adds `place` unless it is already saved or is the current location. Returns whether it was added.
    @discardableResult
    public func add(_ place: Place) async -> Bool {
        guard !places.contains(where: { $0.id == place.id }), currentPlace?.id != place.id else {
            return false
        }
        places.append(place)
        schedulePersist()
        await settlePersistence()
        updateQuery("")
        await loadSummaries()
        return true
    }

    /// Mutates the list immediately so rows never snap back; persistence follows in order.
    public func delete(at offsets: IndexSet) {
        places.remove(atOffsets: offsets)
        schedulePersist()
    }

    public func move(from source: IndexSet, to destination: Int) {
        places.move(fromOffsets: source, toOffset: destination)
        schedulePersist()
    }

    /// Waits for queued saves to finish.
    public func settlePersistence() async {
        await persistTask?.value
    }

    private func schedulePersist() {
        let previous = persistTask
        persistTask = Task {
            await previous?.value
            await persist()
        }
    }

    private func persist() async {
        do {
            try await dependencies.savedPlaces.savePlaces(places)
            persistError = nil
        } catch {
            persistError = WeatherError.wrap(error)
        }
    }

    // MARK: Search

    /// Records the text and schedules a debounced search. Short text clears results.
    public func updateQuery(_ text: String) {
        query = text
        searchTask?.cancel()
        guard isSearching else {
            searchTask = nil
            searchState = .idle
            return
        }
        searchTask = Task { [debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    /// Runs the search for the current query now. Errors become `.failed`, never a crash.
    public func performSearch() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= Self.minimumQueryLength else {
            searchState = .idle
            return
        }
        searchState = .searching
        let outcome: SearchState
        do {
            let found = try await dependencies.geocoding.search(text)
            outcome = found.isEmpty ? .empty : .results(found)
        } catch {
            outcome = .failed(WeatherError.wrap(error))
        }
        // A newer query may have started while this one was in flight.
        guard text == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        searchState = outcome
    }
}
