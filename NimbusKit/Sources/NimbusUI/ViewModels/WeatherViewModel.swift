import Foundation
import Observation
import NimbusCore

/// Loads one place's forecast with stale-while-revalidate: cache first, then the network.
@MainActor
@Observable
public final class WeatherViewModel {
    /// How trustworthy the displayed forecast is.
    public enum Freshness: Sendable, Hashable {
        /// Fetched from the network, or cached and younger than `freshnessWindow`.
        case live
        /// Cached data shown while a refresh runs, or after a refresh failed for a non-network reason.
        case cached
        /// Cached data kept because the device is offline.
        case offline
    }

    public enum LoadState: Sendable, Equatable {
        case loading
        case loaded(Forecast, Freshness)
        case failed(WeatherError)
    }

    /// A cached forecast younger than this skips the network refresh.
    public static let freshnessWindow: TimeInterval = 600

    public let place: Place
    public private(set) var state: LoadState = .loading
    public private(set) var isRefreshing = false

    private let repository: any ForecastRepository
    private let now: @Sendable () -> Date

    public init(place: Place, dependencies: AppDependencies) {
        self.place = place
        self.repository = dependencies.forecasts
        self.now = dependencies.now
    }

    /// The loaded forecast, if any.
    public var forecast: Forecast? {
        if case .loaded(let forecast, _) = state { return forecast }
        return nil
    }

    /// Initial load: show the cache immediately, refresh unless the cache is fresh.
    public func load() async {
        await run(force: false)
    }

    /// Pull to refresh: always asks the network.
    public func refresh() async {
        await run(force: true)
    }

    /// Retry after a failure.
    public func retry() async {
        await run(force: true)
    }

    private func run(force: Bool) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let cached = await repository.cachedForecast(for: place)
        if let cached {
            let age = now().timeIntervalSince(cached.fetchedAt)
            if !force, age >= 0, age < Self.freshnessWindow {
                state = .loaded(cached, .live)
                return
            }
            state = .loaded(cached, .cached)
        } else {
            state = .loading
        }

        do {
            state = .loaded(try await repository.refreshForecast(for: place), .live)
        } catch {
            let error = WeatherError.wrap(error)
            if let cached {
                state = .loaded(cached, error == .offline ? .offline : .cached)
            } else {
                state = .failed(error)
            }
        }
    }
}
