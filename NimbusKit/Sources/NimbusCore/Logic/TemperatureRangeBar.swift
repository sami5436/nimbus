import Foundation

/// Fractions along the 10-day row's track, all in 0...1.
public struct RangeBarLayout: Sendable, Hashable {
    /// Where the day's low starts.
    public var start: Double
    /// Where the day's high ends. Always >= start.
    public var end: Double
    /// Current-temperature dot, only for today's row.
    public var marker: Double?

    public init(start: Double, end: Double, marker: Double? = nil) {
        self.start = start
        self.end = end
        self.marker = marker
    }
}

/// Apple Weather style range bars: each day's bar spans [low, high] positioned
/// within the whole period's [weekLow, weekHigh].
public enum TemperatureRangeBar {
    /// Values in Celsius. Clamps into 0...1. When weekHigh == weekLow, returns a full-width bar.
    public static func layout(
        low: Double,
        high: Double,
        weekLow: Double,
        weekHigh: Double,
        current: Double? = nil
    ) -> RangeBarLayout {
        // STUB(feat/core-domain)
        RangeBarLayout(start: 0, end: 1, marker: nil)
    }
}

/// Color ramp used to fill range bars: cold blues through greens and yellows to hot reds.
public enum TemperatureColorScale {
    public static func color(celsius: Double) -> PaletteColor {
        // STUB(feat/core-domain)
        PaletteColor(hex: 0x4A90E2)
    }

    /// Ordered stops from `fromCelsius` to `toCelsius`, at least two.
    public static func gradient(fromCelsius: Double, toCelsius: Double) -> [PaletteColor] {
        // STUB(feat/core-domain)
        [color(celsius: fromCelsius), color(celsius: toCelsius)]
    }
}
