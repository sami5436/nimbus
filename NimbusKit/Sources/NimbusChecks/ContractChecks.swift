import Foundation
import SwiftUI
import NimbusCore
import NimbusUI

/// Skeleton-owned. Guards the shared contracts every unit builds on: preview data shape,
/// Codable round trips, fakes, and that offscreen rendering works on this machine.
@MainActor
public enum ContractChecks {
    public static func run(_ c: inout Checker) async {
        let forecast = Forecast.preview

        c.expectEqual(forecast.daily.count, 10, "preview has 10 days")
        c.expect(forecast.hourly.count >= 24, "preview has at least 24 hours")
        c.expect(zip(forecast.hourly, forecast.hourly.dropFirst()).allSatisfy { $0.time < $1.time }, "hourly ascending")
        c.expect(forecast.daily.allSatisfy { $0.lowC <= $0.highC }, "daily low <= high")
        c.expectEqual(forecast.timeZone.identifier, "America/Los_Angeles")

        // Codable round trip: the cache and saved places depend on this.
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let roundTripped = await c.expectNoThrow("Forecast round trip") {
            try decoder.decode(Forecast.self, from: encoder.encode(forecast))
        }
        c.expectEqual(roundTripped, forecast)
        let places = await c.expectNoThrow("Place round trip") {
            try decoder.decode([Place].self, from: encoder.encode(Place.previewSearchResults))
        }
        c.expectEqual(places, Place.previewSearchResults)
        c.expect(Place.previewCurrentLocation.isCurrentLocation)
        c.expect(!Place.previewCupertino.isCurrentLocation)

        // Fakes behave as documented.
        let repository = FakeForecastRepository(refreshResult: .failure(.offline))
        let missing = await repository.cachedForecast(for: .previewCupertino)
        c.expect(missing == nil, "empty fake repository has no cache")
        await c.expectThrows(.exactly(.offline)) {
            _ = try await repository.refreshForecast(for: .previewCupertino)
        }
        await repository.setRefreshResult(.success(forecast))
        _ = await c.expectNoThrow { try await repository.refreshForecast(for: .previewCupertino) }
        let cached = await repository.cachedForecast(for: .previewCupertino)
        c.expectEqual(cached, forecast, "fake repository caches after refresh")

        let dependencies = AppDependencies.preview()
        c.expectEqual(dependencies.now(), Forecast.previewReferenceDate)
        let saved = await c.expectNoThrow { try await dependencies.savedPlaces.loadPlaces() }
        c.expectEqual(saved, [Place.previewCupertino])

        c.expectEqual(WeatherError.wrap(WeatherError.decoding), .decoding)
        c.expectEqual(UnitPreferences.default, UnitPreferences(locale: .current))

        // Offscreen rendering works here, so units can rely on Snapshot for visual checks.
        let size = Snapshot.render(SkyBackground(theme: .clearDay), name: "contract-sky")
        c.expect(size == CGSize(width: 780, height: 1688), "ImageRenderer produced \(String(describing: size))")
    }
}
