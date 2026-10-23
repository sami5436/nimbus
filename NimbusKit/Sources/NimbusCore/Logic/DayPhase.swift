import Foundation

public enum DayPhase {
    /// True between sunrise (inclusive) and sunset (exclusive).
    /// With nil sunrise/sunset (polar day or night) uses `fallback`.
    /// Used to recompute day/night for a cached forecast at the current time.
    public static func isDaylight(at date: Date, sunrise: Date?, sunset: Date?, fallback: Bool) -> Bool {
        guard let sunrise, let sunset else { return fallback }
        return date >= sunrise && date < sunset
    }
}
