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
        // STUB(feat/core-domain)
        Capsule().frame(height: 4)
    }
}
