import Foundation
import NimbusCore

/// `GeocodingService` backed by https://geocoding-api.open-meteo.com/v1/search (no API key).
/// Note: the API omits the `results` key entirely when nothing matches.
public struct OpenMeteoGeocodingService: GeocodingService {
    private let client: any HTTPClient
    private let baseURL: URL

    public init(
        client: any HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!
    ) {
        self.client = client
        self.baseURL = baseURL
    }

    public func search(_ query: String) async throws -> [Place] {
        // STUB(feat/data)
        []
    }
}
