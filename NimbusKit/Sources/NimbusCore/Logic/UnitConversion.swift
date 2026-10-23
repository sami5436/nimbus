import Foundation

/// Pure conversions from the canonical model units.
public enum UnitConversion {
    public static func temperature(celsius: Double, to unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius: celsius
        case .fahrenheit: celsius * 9 / 5 + 32
        }
    }

    public static func speed(kmh: Double, to unit: SpeedUnit) -> Double {
        switch unit {
        case .kilometersPerHour: kmh
        case .milesPerHour: kmh / 1.609344
        }
    }

    /// Kilometers, or miles when `imperial`.
    public static func visibility(meters: Double, imperial: Bool) -> Double {
        imperial ? meters / 1609.344 : meters / 1000
    }

    /// Millimeters, or inches when `imperial`.
    public static func precipitation(mm: Double, imperial: Bool) -> Double {
        imperial ? mm / 25.4 : mm
    }

    /// hPa, or inHg when `imperial`.
    public static func pressure(hPa: Double, imperial: Bool) -> Double {
        imperial ? hPa * 0.02952998 : hPa
    }
}
