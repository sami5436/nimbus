import SwiftUI
import NimbusCore

extension WeatherError {
    /// Short headline for a failure state.
    public var displayTitle: String {
        switch self {
        case .offline: "You're Offline"
        case .server, .decoding, .unknown: "Weather Unavailable"
        case .locationPermissionDenied: "Location Is Off"
        case .locationUnavailable: "No Location"
        }
    }

    /// One sentence the user can act on.
    public var displayMessage: String {
        switch self {
        case .offline: "Connect to the internet and try again."
        case .server(let code): "The weather service had a problem (code \(code)). Try again in a moment."
        case .decoding: "The weather data could not be read. Try again later."
        case .locationPermissionDenied: "Allow location access in Settings, or search for a city."
        case .locationUnavailable: "Your location could not be determined. Search for a city instead."
        case .unknown: "Something went wrong. Try again."
        }
    }

    var symbolName: String {
        switch self {
        case .offline: "wifi.slash"
        case .locationPermissionDenied, .locationUnavailable: "location.slash"
        case .server, .decoding, .unknown: "exclamationmark.triangle"
        }
    }
}

/// Shared layout for full-screen messages: symbol, title, message, optional button.
struct MessageStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.85))
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.25))
                    .padding(.top, 8)
            }
        }
        .foregroundStyle(.white)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let error: WeatherError
    let retry: () -> Void

    var body: some View {
        MessageStateView(
            symbol: error.symbolName,
            title: error.displayTitle,
            message: error.displayMessage,
            actionTitle: "Try Again",
            action: retry
        )
    }
}

/// Placeholder shaped like the loaded screen so the layout does not jump.
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                ProgressView().tint(.white).padding(.bottom, 8)
                Text("Loading").font(.title3)
                Text("--°").font(.system(size: 80, weight: .thin))
            }
            .padding(.top, 60)
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .frame(height: 110)
            }
            Spacer()
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 16)
        .accessibilityLabel("Loading weather")
    }
}

/// Banner above the forecast when showing cached data.
struct OfflineBanner: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "wifi.slash")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.25), in: Capsule())
    }
}
