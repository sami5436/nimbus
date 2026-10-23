import Foundation

/// Every user-visible number and time label goes through this type.
/// Temperatures round to whole degrees and never render as "-0°".
public struct WeatherFormatter: Sendable {
    public var preferences: UnitPreferences
    public var locale: Locale

    public init(preferences: UnitPreferences, locale: Locale = .current) {
        self.preferences = preferences
        self.locale = locale
    }

    /// "72°"
    public func temperature(_ celsius: Double) -> String {
        // STUB(feat/core-domain)
        "\(Int(celsius))°"
    }

    /// "72°F"
    public func temperatureWithUnit(_ celsius: Double) -> String {
        // STUB(feat/core-domain)
        temperature(celsius)
    }

    /// "12 mph" or "19 km/h"
    public func windSpeed(_ kmh: Double) -> String {
        // STUB(feat/core-domain)
        "\(Int(kmh))"
    }

    /// 16-point compass, "N", "NNE" ... "NNW". Input in degrees, any range.
    public func compassDirection(degrees: Double) -> String {
        // STUB(feat/core-domain)
        "N"
    }

    /// "10 mi" or "16 km"
    public func visibility(_ meters: Double) -> String {
        // STUB(feat/core-domain)
        "\(Int(meters))"
    }

    /// "0.2 in" or "4 mm"
    public func precipitation(_ mm: Double) -> String {
        // STUB(feat/core-domain)
        "\(mm)"
    }

    /// "29.92 inHg" or "1013 hPa"
    public func pressure(_ hPa: Double) -> String {
        // STUB(feat/core-domain)
        "\(Int(hPa))"
    }

    /// "87%"
    public func percent(_ value: Double) -> String {
        // STUB(feat/core-domain)
        "\(Int(value))%"
    }

    /// WHO category: "Low" (0-2), "Moderate" (3-5), "High" (6-7), "Very High" (8-10), "Extreme" (11+).
    public func uvCategory(_ index: Double) -> String {
        // STUB(feat/core-domain)
        ""
    }

    /// "Now" when `isNow`, else "3PM" (locale-aware hour), in the forecast's time zone.
    public func hourLabel(_ date: Date, timeZone: TimeZone, isNow: Bool) -> String {
        // STUB(feat/core-domain)
        isNow ? "Now" : ""
    }

    /// "Today" when `isToday`, else abbreviated weekday "Tue", in the forecast's time zone.
    public func weekdayLabel(_ date: Date, timeZone: TimeZone, isToday: Bool) -> String {
        // STUB(feat/core-domain)
        isToday ? "Today" : ""
    }

    /// "7:12 AM", in the forecast's time zone.
    public func clockTime(_ date: Date, timeZone: TimeZone) -> String {
        // STUB(feat/core-domain)
        ""
    }
}
