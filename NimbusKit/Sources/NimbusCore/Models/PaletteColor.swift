import Foundation

/// Platform-neutral color so Core can own palettes (sky gradients, temperature scale)
/// without importing SwiftUI. NimbusUI converts with `Color(_ rgb: PaletteColor)`.
public struct PaletteColor: Sendable, Hashable, Codable {
    /// Components in 0...1, sRGB.
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    /// `PaletteColor(hex: 0x4A90E2)`
    public init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
