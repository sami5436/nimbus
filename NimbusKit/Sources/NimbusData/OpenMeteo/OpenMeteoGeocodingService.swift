import Foundation
import NimbusCore

/// `GeocodingService` backed by https://geocoding-api.open-meteo.com/v1/search (no API key).
/// Note: the API omits the `results` key entirely when nothing matches.
public struct OpenMeteoGeocodingService: GeocodingService {
    private let client: any HTTPClient
    private let baseURL: URL

    public static let defaultBaseURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!

    public init(
        client: any HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = OpenMeteoGeocodingService.defaultBaseURL
    ) {
        self.client = client
        self.baseURL = baseURL
    }

    public func search(_ query: String) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let dto = try await OpenMeteoHTTP.fetch(
            OpenMeteoGeocodingDTO.self, from: Self.url(for: trimmed, baseURL: baseURL), using: client)
        return dto.toPlaces()
    }

    /// The request URL for `query`. Exposed for checks.
    public static func url(
        for query: String,
        baseURL: URL = OpenMeteoGeocodingService.defaultBaseURL
    ) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        // URLQueryItem leaves "+" and "&" alone, which would corrupt names like "C++", so encode by hand.
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let name = query.addingPercentEncoding(withAllowedCharacters: unreserved) ?? query
        components.percentEncodedQueryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        return components.url!
    }
}
