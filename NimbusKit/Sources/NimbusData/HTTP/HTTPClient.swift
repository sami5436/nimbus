import Foundation
import NimbusCore

/// Minimal transport seam so Open-Meteo services are checkable offline with canned responses.
public protocol HTTPClient: Sendable {
    /// Returns the body and HTTP status code. Throws `WeatherError` (URLError mapped to `.offline`).
    func get(_ url: URL) async throws -> (data: Data, statusCode: Int)
}

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(_ url: URL) async throws -> (data: Data, statusCode: Int) {
        // STUB(feat/data): perform the request, map URLError codes to WeatherError.offline.
        throw WeatherError.unknown("URLSessionHTTPClient not implemented")
    }
}
