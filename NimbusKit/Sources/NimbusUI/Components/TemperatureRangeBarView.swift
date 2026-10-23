import SwiftUI
import NimbusCore

/// Capsule track with a temperature-colored segment from `TemperatureRangeBar.layout`.
public struct TemperatureRangeBarView: View {
    private let low: Double
    private let high: Double
    private let weekLow: Double
    private let weekHigh: Double
    private let current: Double?

    /// All values in Celsius.
    public init(low: Double, high: Double, weekLow: Double, weekHigh: Double, current: Double? = nil) {
        self.low = low
        self.high = high
        self.weekLow = weekLow
        self.weekHigh = weekHigh
        self.current = current
    }

    public var body: some View {
        let layout = TemperatureRangeBar.layout(
            low: low, high: high, weekLow: weekLow, weekHigh: weekHigh, current: current)
        let colors = TemperatureColorScale.gradient(fromCelsius: low, toCelsius: high).map(Color.init)
        GeometryReader { proxy in
            let width = proxy.size.width
            let segment = max(layout.end - layout.start, 0) * width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.22))
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(segment, 4))
                    .offset(x: min(layout.start * width, width - max(segment, 4)))
                if let marker = layout.marker {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1.5))
                        .offset(x: min(max(marker * width - 3, 0), width - 6))
                }
            }
            .frame(height: proxy.size.height)
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}
