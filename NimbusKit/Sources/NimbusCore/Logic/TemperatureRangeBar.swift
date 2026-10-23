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
        let span = weekHigh - weekLow
        guard span > 0 else {
            return RangeBarLayout(start: 0, end: 1, marker: current == nil ? nil : 0.5)
        }
        func fraction(_ value: Double) -> Double { min(max((value - weekLow) / span, 0), 1) }
        let start = fraction(low)
        return RangeBarLayout(start: start, end: max(start, fraction(high)), marker: current.map(fraction))
    }
}

/// Color ramp used to fill range bars: cold blues through greens and yellows to hot reds.
public enum TemperatureColorScale {
    private static let stops: [(celsius: Double, color: PaletteColor)] = [
        (-10, PaletteColor(hex: 0x4B6CF0)),
        (0, PaletteColor(hex: 0x4AA3F5)),
        (10, PaletteColor(hex: 0x52C7C0)),
        (18, PaletteColor(hex: 0x8BD36B)),
        (24, PaletteColor(hex: 0xF2D04A)),
        (30, PaletteColor(hex: 0xF59A3A)),
        (38, PaletteColor(hex: 0xE5453B)),
    ]

    public static func color(celsius: Double) -> PaletteColor {
        guard let first = stops.first, let last = stops.last else { return PaletteColor(hex: 0xFFFFFF) }
        if celsius <= first.celsius { return first.color }
        if celsius >= last.celsius { return last.color }
        for (lower, upper) in zip(stops, stops.dropFirst()) where celsius <= upper.celsius {
            let t = (celsius - lower.celsius) / (upper.celsius - lower.celsius)
            return PaletteColor(
                red: lower.color.red + (upper.color.red - lower.color.red) * t,
                green: lower.color.green + (upper.color.green - lower.color.green) * t,
                blue: lower.color.blue + (upper.color.blue - lower.color.blue) * t
            )
        }
        return last.color
    }

    /// Ordered stops from `fromCelsius` to `toCelsius`, at least two.
    public static func gradient(fromCelsius: Double, toCelsius: Double) -> [PaletteColor] {
        let steps = 6
        return (0...steps).map { step in
            color(celsius: fromCelsius + (toCelsius - fromCelsius) * Double(step) / Double(steps))
        }
    }
}
