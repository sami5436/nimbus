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

    /// Fills `summaries` from the cache, fetching only for places that have never been loaded.
    public func loadSummaries() async {
        for place in displayPlaces {
            var forecast = await dependencies.forecasts.cachedForecast(for: place)
            if forecast == nil {
                forecast = try? await dependencies.forecasts.refreshForecast(for: place)
            }
            guard let forecast else { continue }
            let today = forecast.daily.first
            summaries[place.id] = PlaceSummary(
                temperatureC: forecast.current.temperatureC,
                highC: today?.highC,
                lowC: today?.lowC,
                condition: forecast.current.condition,
                isDaylight: forecast.current.isDaylight
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
        await persist()
        updateQuery("")
        await loadSummaries()
        return true
    }

    public func delete(at offsets: IndexSet) async {
        places.remove(atOffsets: offsets)
        await persist()
    }

    public func move(from source: IndexSet, to destination: Int) async {
        places.move(fromOffsets: source, toOffset: destination)
        await persist()
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
