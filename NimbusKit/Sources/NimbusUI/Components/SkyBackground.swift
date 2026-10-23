import SwiftUI
import NimbusCore

/// Full-bleed gradient for a `SkyTheme`. Place behind content with `.ignoresSafeArea()`.
/// Changing the theme cross-fades; night themes get a faint star field.
public struct SkyBackground: View {
    private let theme: SkyTheme

    public init(theme: SkyTheme) {
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            LinearGradient(colors: theme.gradient.map(Color.init), startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .top) { glow }
                .overlay { if theme.isNight { Stars() } }
                .id(theme)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.8), value: theme)
        .ignoresSafeArea()
    }

    private var glow: some View {
        RadialGradient(
            colors: [Color.white.opacity(theme.isNight ? 0.08 : 0.28), .clear],
            center: .top, startRadius: 0, endRadius: 360
        )
        .frame(height: 420)
    }
}

/// Deterministic scatter of dots, so snapshots are stable.
private struct Stars: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 42
            func next() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 33) / Double(1 << 31)
            }
            for _ in 0..<70 {
                let x = next() * size.width
                let y = next() * size.height * 0.55
                let radius = 0.4 + next() * 0.9
                let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.25 + next() * 0.5)))
            }
        }
        .allowsHitTesting(false)
    }
}
