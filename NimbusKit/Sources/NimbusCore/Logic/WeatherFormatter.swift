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
        let value = UnitConversion.temperature(celsius: celsius, to: preferences.temperature)
        // Int conversion drops the sign of negative zero.
        return "\(Int(value.rounded()))°"
    }

    /// "72°F"
    public func temperatureWithUnit(_ celsius: Double) -> String {
        temperature(celsius) + (preferences.temperature == .fahrenheit ? "F" : "C")
    }

    /// "12 mph" or "19 km/h"
    public func windSpeed(_ kmh: Double) -> String {
        let value = UnitConversion.speed(kmh: kmh, to: preferences.speed)
        let unit = preferences.speed == .milesPerHour ? "mph" : "km/h"
        return "\(Int(value.rounded())) \(unit)"
    }

    /// 16-point compass, "N", "NNE" ... "NNW". Input in degrees, any range.
    public func compassDirection(degrees: Double) -> String {
        let names = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                     "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees / 22.5).rounded()) % 16
        return names[(index + 16) % 16]
    }

    /// "10 mi" or "16 km"
    public func visibility(_ meters: Double) -> String {
        let imperial = preferences.usesImperialMeasures
        let value = UnitConversion.visibility(meters: meters, imperial: imperial)
        let unit = imperial ? "mi" : "km"
        return "\(number(value, decimals: value < 1 ? 1 : 0)) \(unit)"
    }

    /// "0.2 in" or "4 mm"
    public func precipitation(_ mm: Double) -> String {
        let imperial = preferences.usesImperialMeasures
        let value = UnitConversion.precipitation(mm: mm, imperial: imperial)
        return imperial ? "\(number(value, decimals: 1)) in" : "\(number(value, decimals: 0)) mm"
    }

    /// "29.92 inHg" or "1013 hPa"
    public func pressure(_ hPa: Double) -> String {
        let imperial = preferences.usesImperialMeasures
        let value = UnitConversion.pressure(hPa: hPa, imperial: imperial)
        return imperial ? "\(number(value, decimals: 2)) inHg" : "\(number(value, decimals: 0)) hPa"
    }

    /// "87%"
    public func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    /// WHO category: "Low" (0-2), "Moderate" (3-5), "High" (6-7), "Very High" (8-10), "Extreme" (11+).
    public func uvCategory(_ index: Double) -> String {
        switch index.rounded(.down) {
        case ..<3: "Low"
        case ..<6: "Moderate"
        case ..<8: "High"
        case ..<11: "Very High"
        default: "Extreme"
        }
    }

    /// "Now" when `isNow`, else "3PM" (locale-aware hour), in the forecast's time zone.
    public func hourLabel(_ date: Date, timeZone: TimeZone, isNow: Bool) -> String {
        if isNow { return "Now" }
        return format(date, template: "j", timeZone: timeZone).filter { !$0.isWhitespace }
    }

    /// "Today" when `isToday`, else abbreviated weekday "Tue", in the forecast's time zone.
    public func weekdayLabel(_ date: Date, timeZone: TimeZone, isToday: Bool) -> String {
        isToday ? "Today" : format(date, template: "EEE", timeZone: timeZone)
    }

    /// "7:12 AM", in the forecast's time zone.
    public func clockTime(_ date: Date, timeZone: TimeZone) -> String {
        format(date, template: "jmm", timeZone: timeZone)
    }

    private func number(_ value: Double, decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func format(_ date: Date, template: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        // Newer ICU uses a narrow no-break space before AM/PM; normalize to a plain space.
        return formatter.string(from: date)
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
