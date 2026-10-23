import Foundation

/// The only error type that crosses module boundaries. Services and repositories throw this.
public enum WeatherError: Error, Sendable, Hashable {
    /// No connectivity (URLError not connected, connection lost, timed out, and similar).
    case offline
    /// Non-2xx HTTP response.
    case server(statusCode: Int)
    /// Response body did not match the expected schema.
    case decoding
    case locationPermissionDenied
    case locationUnavailable
    case unknown(String)

    /// Passes `WeatherError` through, wraps anything else as `.unknown`.
    /// Network-specific mapping (URLError to `.offline`) lives in NimbusData.
    public static func wrap(_ error: any Error) -> WeatherError {
        if let error = error as? WeatherError { return error }
        return .unknown(String(describing: error))
    }
}
