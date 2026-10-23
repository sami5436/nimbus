import Foundation

/// Condition buckets derived from WMO weather interpretation codes (Open-Meteo `weather_code`).
public enum WeatherCondition: String, Sendable, Hashable, Codable, CaseIterable {
    case clear
    case mainlyClear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case freezingDrizzle
    case rain
    case heavyRain
    case freezingRain
    case snow
    case heavySnow
    case snowGrains
    case rainShowers
    case snowShowers
    case thunderstorm
    case thunderstormWithHail
    case unknown

    /// Maps a WMO code (0, 1, 2, 3, 45, 48, 51...99) to a condition. Unrecognized codes map to `.unknown`.
    public init(wmoCode: Int) {
        // STUB(feat/core-domain): implement the full WMO table.
        self = .unknown
    }

    /// SF Symbol name, using the `.fill` multicolor variants and night variants where they exist.
    public func symbolName(isDaylight: Bool) -> String {
        // STUB(feat/core-domain)
        "questionmark"
    }

    /// Short human description, e.g. "Partly Cloudy".
    public var displayName: String {
        // STUB(feat/core-domain)
        rawValue
    }
}
