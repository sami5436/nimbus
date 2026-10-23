import SwiftUI
import NimbusCore

extension Color {
    public init(_ palette: PaletteColor) {
        self.init(.sRGB, red: palette.red, green: palette.green, blue: palette.blue, opacity: palette.opacity)
    }
}
