import Foundation

public enum TemperatureUnit: String, Sendable, Hashable, Codable, CaseIterable {
    case celsius
    case fahrenheit
}

public enum SpeedUnit: String, Sendable, Hashable, Codable, CaseIterable {
    case kilometersPerHour
    case milesPerHour
}

/// User-selected display units. Persisted by `PreferencesStore`.
public struct UnitPreferences: Sendable, Hashable, Codable {
    public var temperature: TemperatureUnit
    public var speed: SpeedUnit

    public init(temperature: TemperatureUnit, speed: SpeedUnit) {
        self.temperature = temperature
        self.speed = speed
    }

    /// Defaults follow the device locale: Fahrenheit and mph for US, Celsius and mph for UK, metric elsewhere.
    public static var `default`: UnitPreferences { UnitPreferences(locale: .current) }

    public init(locale: Locale) {
        switch locale.measurementSystem {
        case .us: self.init(temperature: .fahrenheit, speed: .milesPerHour)
        case .uk: self.init(temperature: .celsius, speed: .milesPerHour)
        default: self.init(temperature: .celsius, speed: .kilometersPerHour)
        }
    }

    /// Distance, precipitation and pressure follow the speed toggle:
    /// mph means miles, inches and inHg; km/h means kilometers, millimeters and hPa.
    public var usesImperialMeasures: Bool { speed == .milesPerHour }
}
