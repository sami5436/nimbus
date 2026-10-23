import SwiftUI

extension View {
    /// Translucent rounded card used by every forecast section.
    func weatherCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Small caps section title with an SF Symbol, shared by cards and tiles.
struct CardHeader: View {
    let title: String
    let symbol: String

    var body: some View {
        Label {
            Text(title.uppercased())
        } icon: {
            Image(systemName: symbol)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.white.opacity(0.6))
    }
}
