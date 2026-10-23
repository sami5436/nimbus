import Foundation

/// Pure conversions from the canonical model units.
public enum UnitConversion {
    public static func temperature(celsius: Double, to unit: TemperatureUnit) -> Double {
        // STUB(feat/core-domain)
        celsius
    }

    public static func speed(kmh: Double, to unit: SpeedUnit) -> Double {
        // STUB(feat/core-domain)
        kmh
    }

    /// Kilometers, or miles when `imperial`.
    public static func visibility(meters: Double, imperial: Bool) -> Double {
        // STUB(feat/core-domain)
        meters
    }

    /// Millimeters, or inches when `imperial`.
    public static func precipitation(mm: Double, imperial: Bool) -> Double {
        // STUB(feat/core-domain)
        mm
    }

    /// hPa, or inHg when `imperial`.
    public static func pressure(hPa: Double, imperial: Bool) -> Double {
        // STUB(feat/core-domain)
        hPa
    }
}
