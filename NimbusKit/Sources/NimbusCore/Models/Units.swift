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

    public static let `default` = UnitPreferences(temperature: .fahrenheit, speed: .milesPerHour)

    /// Distance, precipitation and pressure follow the speed toggle:
    /// mph means miles, inches and inHg; km/h means kilometers, millimeters and hPa.
    public var usesImperialMeasures: Bool { speed == .milesPerHour }
}
