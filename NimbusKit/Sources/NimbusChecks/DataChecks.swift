import Foundation
import NimbusCore
import NimbusData

/// Canned HTTP transport that records requested URLs. Never touches the network.
private final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    enum Outcome: Sendable {
        case response(Data, Int)
        case failure(WeatherError)
    }

    private let lock = NSLock()
    private let outcome: Outcome
    private var recorded: [URL] = []

    init(_ outcome: Outcome) { self.outcome = outcome }

    convenience init(data: Data, status: Int = 200) { self.init(.response(data, status)) }

    var urls: [URL] { lock.withLock { recorded } }

    func get(_ url: URL) async throws -> (data: Data, statusCode: Int) {
        lock.withLock { recorded.append(url) }
        switch outcome {
        case .response(let data, let status): return (data, status)
        case .failure(let error): throw error
        }
    }
}

/// Weather service that succeeds once with a fixed forecast or always throws.
private struct StubWeatherService: WeatherService {
    let result: Result<Forecast, WeatherError>
    func forecast(for coordinate: Coordinate) async throws -> Forecast { try result.get() }
}

/// Owned by feat/data.
@MainActor
public enum DataChecks {
    private static let cupertino = Coordinate(latitude: 37.323, longitude: -122.0322)

    public static func run(_ c: inout Checker) async {
        await forecastMapping(&c)
        await geocoding(&c)
        await urls(&c)
        await errorMapping(&c)
        await persistence(&c)
        await repository(&c)
    }

    private static func queryItems(_ url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    private static func loadForecast() async -> Forecast? {
        guard let data = try? Fixture.data("forecast_cupertino") else { return nil }
        return try? await OpenMeteoWeatherService(client: StubHTTPClient(data: data)).forecast(for: cupertino)
    }

    // MARK: Forecast mapping

    private static func forecastMapping(_ c: inout Checker) async {
        guard let f = await loadForecast() else {
            c.expect(false, "forecast fixture failed to load and map")
            return
        }
        c.expectEqual(f.daily.count, 10, "daily count")
        c.expectEqual(f.hourly.count, 240, "hourly count")
        c.expectEqual(f.timeZoneIdentifier, "America/Los_Angeles")
        c.expectEqual(f.coordinate, cupertino, "requested coordinate is preserved")
        c.expect(abs(f.fetchedAt.timeIntervalSinceNow) < 60, "fetchedAt is now")

        let cur = f.current
        c.expectEqual(cur.time, Date(timeIntervalSince1970: 1792728900))
        c.expectClose(cur.temperatureC, 14.7)
        c.expectClose(cur.apparentTemperatureC, 14.9)
        c.expectClose(cur.relativeHumidityPercent, 87)
        c.expectClose(cur.windSpeedKmh, 4.3)
        c.expectClose(cur.windDirectionDegrees, 345)
        c.expectEqual(cur.windGustsKmh, 15.1)
        c.expectClose(cur.pressureHPa, 1015)
        c.expectClose(cur.visibilityMeters, 16000)
        c.expectClose(cur.precipitationMm, 0)
        c.expectClose(cur.uvIndex, 0)
        c.expectEqual(cur.isDaylight, false, "is_day 0 is night")
        c.expectEqual(cur.condition, WeatherCondition(wmoCode: 3))

        let h0 = f.hourly[0]
        c.expectEqual(h0.time, Date(timeIntervalSince1970: 1792652400))
        c.expectClose(h0.temperatureC, 14.9)
        c.expectEqual(h0.condition, WeatherCondition(wmoCode: 0))
        c.expectEqual(h0.isDaylight, false)
        c.expectEqual(h0.precipitationProbabilityPercent, 16)
        c.expectEqual(f.hourly[8].isDaylight, true, "is_day 1 is daylight")
        c.expectEqual(f.hourly[4].condition, WeatherCondition(wmoCode: 51))
        c.expectEqual(f.hourly[239].time, Date(timeIntervalSince1970: 1793512800))
        let steps = zip(f.hourly, f.hourly.dropFirst()).allSatisfy { $1.time.timeIntervalSince($0.time) == 3600 }
        c.expect(steps, "hourly entries are one hour apart")

        let d0 = f.daily[0]
        c.expectEqual(d0.date, Date(timeIntervalSince1970: 1792652400))
        c.expectEqual(d0.condition, WeatherCondition(wmoCode: 55))
        c.expectClose(d0.highC, 16.3)
        c.expectClose(d0.lowC, 13.1)
        c.expectClose(d0.precipitationSumMm, 3.5)
        c.expectEqual(d0.precipitationProbabilityPercent, 58)
        c.expectEqual(d0.sunrise, Date(timeIntervalSince1970: 1792678981))
        c.expectEqual(d0.sunset, Date(timeIntervalSince1970: 1792718497))
        c.expectEqual(d0.uvIndexMax, 2.85)
        c.expect(f.daily.allSatisfy { $0.sunrise != nil && $0.sunset != nil }, "every day has sun times")
        c.expect(f.daily.allSatisfy { $0.lowC <= $0.highC }, "low <= high")
        c.expectEqual(f.daily[9].highC, 18.5)

        let encoded = try? JSONEncoder().encode(f)
        let decoded = encoded.flatMap { try? JSONDecoder().decode(Forecast.self, from: $0) }
        c.expectEqual(decoded, f, "mapped forecast survives a Codable round trip")
    }

    // MARK: Geocoding

    private static func geocoding(_ c: inout Checker) async {
        if let data = try? Fixture.data("geocoding_cupertino") {
            let service = OpenMeteoGeocodingService(client: StubHTTPClient(data: data))
            if let places = await c.expectNoThrow { try await service.search("Cupertino") } {
                c.expectEqual(places.count, 2)
                let p = places[0]
                c.expectEqual(p.id, "5341145")
                c.expectEqual(p.name, "Cupertino")
                c.expectEqual(p.region, "California")
                c.expectEqual(p.country, "United States")
                c.expectEqual(p.coordinate, Coordinate(latitude: 37.323, longitude: -122.03218))
                c.expectEqual(p.timeZoneIdentifier, "America/Los_Angeles")
                c.expectEqual(places[1].id, "3742459")
                c.expectEqual(places[1].country, "Venezuela")
            }
        } else {
            c.expect(false, "geocoding_cupertino fixture missing")
        }

        if let data = try? Fixture.data("geocoding_empty") {
            let service = OpenMeteoGeocodingService(client: StubHTTPClient(data: data))
            let places = await c.expectNoThrow { try await service.search("zzzzqqxx") }
            c.expectEqual(places ?? [Place(id: "x", name: "x", coordinate: cupertino)], [], "no results key is []")
        } else {
            c.expect(false, "geocoding_empty fixture missing")
        }

        let stub = StubHTTPClient(data: Data("{}".utf8))
        let service = OpenMeteoGeocodingService(client: stub)
        let blank = await c.expectNoThrow { try await service.search("   ") }
        c.expectEqual(blank?.count, 0, "blank query returns []")
        c.expectEqual(stub.urls.count, 0, "blank query does not hit the network")

        let bad = OpenMeteoGeocodingService(client: StubHTTPClient(data: Data(), status: 503))
        await c.expectThrows(.exactly(.server(statusCode: 503))) { _ = try await bad.search("Paris") }
    }

    // MARK: URL building

    private static func urls(_ c: inout Checker) async {
        let url = OpenMeteoWeatherService.url(for: cupertino)
        c.expectEqual(url.host, "api.open-meteo.com")
        c.expectEqual(url.path, "/v1/forecast")
        let q = queryItems(url)
        c.expectEqual(q["latitude"], "37.323")
        c.expectEqual(q["longitude"], "-122.0322")
        c.expectEqual(q["timezone"], "auto")
        c.expectEqual(q["timeformat"], "unixtime")
        c.expectEqual(q["forecast_days"], "10")
        let current = Set((q["current"] ?? "").split(separator: ",").map(String.init))
        for key in ["temperature_2m", "apparent_temperature", "relative_humidity_2m", "is_day", "weather_code",
                    "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m", "pressure_msl", "visibility",
                    "precipitation", "uv_index"] {
            c.expect(current.contains(key), "current has \(key)")
        }
        let hourly = Set((q["hourly"] ?? "").split(separator: ",").map(String.init))
        for key in ["temperature_2m", "weather_code", "is_day", "precipitation_probability"] {
            c.expect(hourly.contains(key), "hourly has \(key)")
        }
        let daily = Set((q["daily"] ?? "").split(separator: ",").map(String.init))
        for key in ["weather_code", "temperature_2m_max", "temperature_2m_min", "sunrise", "sunset",
                    "uv_index_max", "precipitation_sum", "precipitation_probability_max"] {
            c.expect(daily.contains(key), "daily has \(key)")
        }

        let custom = URL(string: "https://example.test/forecast")!
        c.expectEqual(OpenMeteoWeatherService.url(for: cupertino, baseURL: custom).host, "example.test")

        let stub = StubHTTPClient(data: (try? Fixture.data("forecast_cupertino")) ?? Data())
        _ = try? await OpenMeteoWeatherService(client: stub).forecast(for: cupertino)
        c.expectEqual(stub.urls.first, url, "service requests the built URL")

        let g = queryItems(OpenMeteoGeocodingService.url(for: "San José"))
        c.expectEqual(g["name"], "San José")
        c.expectEqual(g["count"], "10")
        c.expectEqual(g["language"], "en")
        c.expectEqual(g["format"], "json")
        let plus = OpenMeteoGeocodingService.url(for: "C++ & Co")
        c.expect(plus.absoluteString.contains("name=C%2B%2B%20%26%20Co"), "reserved characters are encoded: \(plus)")
        c.expectEqual(OpenMeteoGeocodingService.url(for: "x").host, "geocoding-api.open-meteo.com")
    }

    // MARK: Error mapping

    private static func errorMapping(_ c: inout Checker) async {
        let valid = (try? Fixture.data("forecast_cupertino")) ?? Data()

        let server = OpenMeteoWeatherService(client: StubHTTPClient(data: valid, status: 500))
        await c.expectThrows(.exactly(.server(statusCode: 500))) { _ = try await server.forecast(for: cupertino) }
        let limited = OpenMeteoWeatherService(client: StubHTTPClient(data: Data(), status: 429))
        await c.expectThrows(.exactly(.server(statusCode: 429))) { _ = try await limited.forecast(for: cupertino) }

        let malformed = (try? Fixture.data("malformed")) ?? Data()
        let bad = OpenMeteoWeatherService(client: StubHTTPClient(data: malformed))
        await c.expectThrows(.exactly(.decoding)) { _ = try await bad.forecast(for: cupertino) }
        let empty = OpenMeteoWeatherService(client: StubHTTPClient(data: Data()))
        await c.expectThrows(.exactly(.decoding)) { _ = try await empty.forecast(for: cupertino) }
        let wrongShape = OpenMeteoWeatherService(client: StubHTTPClient(data: Data("{\"a\":1}".utf8)))
        await c.expectThrows(.exactly(.decoding)) { _ = try await wrongShape.forecast(for: cupertino) }
        let badGeo = OpenMeteoGeocodingService(client: StubHTTPClient(data: malformed))
        await c.expectThrows(.exactly(.decoding)) { _ = try await badGeo.search("x") }

        let offline = OpenMeteoWeatherService(client: StubHTTPClient(.failure(.offline)))
        await c.expectThrows(.exactly(.offline)) { _ = try await offline.forecast(for: cupertino) }

        // URLSessionHTTPClient's URLError mapping, exercised through a stub URLProtocol-free route.
        let session = URLSession(configuration: {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [FailingURLProtocol.self]
            return config
        }())
        let live = URLSessionHTTPClient(session: session)
        await c.expectThrows(.exactly(.offline)) { _ = try await live.get(URL(string: "https://offline.test/")!) }
        FailingURLProtocol.code = .badURL
        await c.expectThrows(.anyWeatherError) { _ = try await live.get(URL(string: "https://offline.test/")!) }
        FailingURLProtocol.code = .timedOut
        await c.expectThrows(.exactly(.offline)) { _ = try await live.get(URL(string: "https://offline.test/")!) }
        FailingURLProtocol.code = .notConnectedToInternet
    }

    // MARK: Persistence

    private static func persistence(_ c: inout Checker) async {
        guard let dir = try? Fixture.temporaryDirectory(), let forecast = await loadForecast() else {
            c.expect(false, "persistence setup failed")
            return
        }
        defer { try? FileManager.default.removeItem(at: dir) }

        let cache = FileForecastCache(directory: dir)
        let missing = await cache.forecast(forPlaceID: "1")
        c.expect(missing == nil, "empty cache reads nil")
        await cache.store(forecast, forPlaceID: "1")
        let hit = await cache.forecast(forPlaceID: "1")
        c.expectEqual(hit, forecast, "cache round trip")
        let other = await cache.forecast(forPlaceID: "2")
        c.expect(other == nil, "cache is keyed by place id")
        await cache.store(forecast, forPlaceID: Place.currentLocationID)
        let current = await cache.forecast(forPlaceID: Place.currentLocationID)
        c.expectEqual(current, forecast, "current-location key round trips")
        await cache.store(forecast, forPlaceID: "../escape")
        let escaped = await cache.forecast(forPlaceID: "../escape")
        c.expectEqual(escaped, forecast, "hostile ids stay inside the cache directory")
        c.expect(!FileManager.default.fileExists(atPath: dir.deletingLastPathComponent().appendingPathComponent("escape.json").path))

        let corruptURL = dir.appendingPathComponent("forecasts").appendingPathComponent("1.json")
        try? Data("not json".utf8).write(to: corruptURL)
        let corrupt = await cache.forecast(forPlaceID: "1")
        c.expect(corrupt == nil, "corrupt cache reads nil")

        let places = FileSavedPlacesStore(directory: dir)
        let none = await c.expectNoThrow { try await places.loadPlaces() }
        c.expectEqual(none, [], "missing places file reads []")
        let saved = [
            Place(id: "5341145", name: "Cupertino", region: "California", country: "United States",
                  coordinate: Coordinate(latitude: 37.323, longitude: -122.03218),
                  timeZoneIdentifier: "America/Los_Angeles"),
            Place(id: "99", name: "Nowhere", coordinate: Coordinate(latitude: 1, longitude: 2)),
        ]
        await c.expectNoThrow { try await places.savePlaces(saved) }
        let loaded = await c.expectNoThrow { try await places.loadPlaces() }
        c.expectEqual(loaded, saved, "places round trip keeps order and optionals")
        let reordered = Array(saved.reversed())
        await c.expectNoThrow { try await places.savePlaces(reordered) }
        let fresh = FileSavedPlacesStore(directory: dir)
        let reloaded = await c.expectNoThrow { try await fresh.loadPlaces() }
        c.expectEqual(reloaded, reordered, "a new store instance reads what was saved")
        try? Data("{{".utf8).write(to: dir.appendingPathComponent("places.json"))
        await c.expectThrows(.exactly(.decoding)) { _ = try await fresh.loadPlaces() }

        let prefs = FilePreferencesStore(directory: dir)
        let initial = await prefs.loadPreferences()
        c.expectEqual(initial, .default, "missing preferences read default")
        let metric = UnitPreferences(temperature: .celsius, speed: .kilometersPerHour)
        await prefs.savePreferences(metric)
        let back = await FilePreferencesStore(directory: dir).loadPreferences()
        c.expectEqual(back, metric, "preferences round trip")
        try? Data("garbage".utf8).write(to: dir.appendingPathComponent("preferences.json"))
        let afterCorrupt = await prefs.loadPreferences()
        c.expectEqual(afterCorrupt, .default, "corrupt preferences read default")

        let nested = dir.appendingPathComponent("a/b", isDirectory: true)
        await FilePreferencesStore(directory: nested).savePreferences(metric)
        let nestedBack = await FilePreferencesStore(directory: nested).loadPreferences()
        c.expectEqual(nestedBack, metric, "stores create missing directories")

        let location = try? StorageLocation.defaultDirectory()
        c.expect(location?.lastPathComponent == "Nimbus", "default directory ends in Nimbus")
        var isDir: ObjCBool = false
        c.expect(location.map { FileManager.default.fileExists(atPath: $0.path, isDirectory: &isDir) } == true && isDir.boolValue,
                 "default directory exists")
    }

    // MARK: Repository

    private static func repository(_ c: inout Checker) async {
        guard let dir = try? Fixture.temporaryDirectory(), let forecast = await loadForecast() else {
            c.expect(false, "repository setup failed")
            return
        }
        defer { try? FileManager.default.removeItem(at: dir) }
        let place = Place(id: "5341145", name: "Cupertino", coordinate: cupertino)
        let cache = FileForecastCache(directory: dir)

        let failing = LiveForecastRepository(service: StubWeatherService(result: .failure(.offline)), cache: cache)
        let none = await failing.cachedForecast(for: place)
        c.expect(none == nil, "nothing cached before first fetch")
        await c.expectThrows(.exactly(.offline)) { _ = try await failing.refreshForecast(for: place) }
        let stillNone = await cache.forecast(forPlaceID: place.id)
        c.expect(stillNone == nil, "failed refresh writes nothing")

        let working = LiveForecastRepository(service: StubWeatherService(result: .success(forecast)), cache: cache)
        let fresh = await c.expectNoThrow { try await working.refreshForecast(for: place) }
        c.expectEqual(fresh, forecast)
        let stored = await cache.forecast(forPlaceID: place.id)
        c.expectEqual(stored, forecast, "successful refresh writes the cache")
        let cached = await working.cachedForecast(for: place)
        c.expectEqual(cached, forecast, "cachedForecast reads it back")

        let server = LiveForecastRepository(service: StubWeatherService(result: .failure(.server(statusCode: 502))), cache: cache)
        await c.expectThrows(.exactly(.server(statusCode: 502))) { _ = try await server.refreshForecast(for: place) }
        let kept = await server.cachedForecast(for: place)
        c.expectEqual(kept, forecast, "failed refresh leaves the previous cache intact")

        // End to end through the real services with a stub transport.
        let data = (try? Fixture.data("forecast_cupertino")) ?? Data()
        let live = LiveForecastRepository(
            service: OpenMeteoWeatherService(client: StubHTTPClient(data: data)),
            cache: FileForecastCache(directory: dir))
        let other = Place(id: "7", name: "Other", coordinate: Coordinate(latitude: 10, longitude: 20))
        let mapped = await c.expectNoThrow { try await live.refreshForecast(for: other) }
        c.expectEqual(mapped?.coordinate, other.coordinate, "forecast carries the place coordinate")
        let otherCached = await live.cachedForecast(for: other)
        c.expectEqual(otherCached, mapped, "per-place cache keys do not collide")
    }
}

/// URLProtocol that fails every request with `code`, so URLError mapping is testable offline.
private final class FailingURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var code: URLError.Code = .notConnectedToInternet

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(Self.code)) }
    override func stopLoading() {}
}
