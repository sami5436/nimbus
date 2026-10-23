import SwiftUI
import NimbusCore

/// Full-bleed gradient for a `SkyTheme`. Place behind content with `.ignoresSafeArea()`.
public struct SkyBackground: View {
    private let theme: SkyTheme

    public init(theme: SkyTheme) {
        self.theme = theme
    }

    public var body: some View {
        // STUB(feat/core-domain): richer treatment (animated change between themes).
        LinearGradient(colors: theme.gradient.map(Color.init), startPoint: .top, endPoint: .bottom)
    }
}
