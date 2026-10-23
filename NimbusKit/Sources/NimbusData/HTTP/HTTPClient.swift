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
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw WeatherError.unknown("Non-HTTP response")
            }
            return (data, http.statusCode)
        } catch let error as WeatherError {
            throw error
        } catch let error as URLError {
            throw Self.map(error)
        } catch {
            throw WeatherError.wrap(error)
        }
    }

    /// Connectivity failures become `.offline`; everything else is `.unknown`.
    static func map(_ error: URLError) -> WeatherError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
             .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff,
             .secureConnectionFailed:
            return .offline
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
