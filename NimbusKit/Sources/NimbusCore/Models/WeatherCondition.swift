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
        switch wmoCode {
        case 0: self = .clear
        case 1: self = .mainlyClear
        case 2: self = .partlyCloudy
        case 3: self = .overcast
        case 45, 48: self = .fog
        case 51, 53, 55: self = .drizzle
        case 56, 57: self = .freezingDrizzle
        case 61, 63: self = .rain
        case 65: self = .heavyRain
        case 66, 67: self = .freezingRain
        case 71, 73: self = .snow
        case 75: self = .heavySnow
        case 77: self = .snowGrains
        case 80, 81, 82: self = .rainShowers
        case 85, 86: self = .snowShowers
        case 95: self = .thunderstorm
        case 96, 99: self = .thunderstormWithHail
        default: self = .unknown
        }
    }

    /// SF Symbol name, using the `.fill` multicolor variants and night variants where they exist.
    public func symbolName(isDaylight: Bool) -> String {
        switch self {
        case .clear: isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .mainlyClear: isDaylight ? "sun.max.fill" : "moon.fill"
        case .partlyCloudy: isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .overcast: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .freezingDrizzle, .freezingRain: "cloud.sleet.fill"
        case .rain: "cloud.rain.fill"
        case .heavyRain: "cloud.heavyrain.fill"
        case .snow, .snowShowers: "cloud.snow.fill"
        case .heavySnow: "wind.snow"
        case .snowGrains: "snowflake"
        case .rainShowers: isDaylight ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .thunderstormWithHail: "cloud.bolt.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }

    /// Short human description, e.g. "Partly Cloudy".
    public var displayName: String {
        switch self {
        case .clear: "Clear"
        case .mainlyClear: "Mostly Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .overcast: "Overcast"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .freezingDrizzle: "Freezing Drizzle"
        case .rain: "Rain"
        case .heavyRain: "Heavy Rain"
        case .freezingRain: "Freezing Rain"
        case .snow: "Snow"
        case .heavySnow: "Heavy Snow"
        case .snowGrains: "Snow Grains"
        case .rainShowers: "Showers"
        case .snowShowers: "Snow Showers"
        case .thunderstorm: "Thunderstorm"
        case .thunderstormWithHail: "Thunderstorm with Hail"
        case .unknown: "Unknown"
        }
    }
}
