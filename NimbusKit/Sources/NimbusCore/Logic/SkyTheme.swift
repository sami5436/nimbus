import Foundation

/// Background mood for a condition and time of day.
public enum SkyTheme: String, Sendable, Hashable, CaseIterable {
    case clearDay, clearNight
    case cloudyDay, cloudyNight
    case rainDay, rainNight
    case snowDay, snowNight
    case stormDay, stormNight
    case fogDay, fogNight

    public init(condition: WeatherCondition, isDaylight: Bool) {
        // STUB(feat/core-domain)
        self = isDaylight ? .clearDay : .clearNight
    }

    /// Vertical gradient stops, top to bottom, at least two.
    public var gradient: [PaletteColor] {
        // STUB(feat/core-domain)
        [PaletteColor(hex: 0x3A7BD5), PaletteColor(hex: 0x6FB1FC)]
    }

    public var isNight: Bool {
        switch self {
        case .clearNight, .cloudyNight, .rainNight, .snowNight, .stormNight, .fogNight: true
        default: false
        }
    }
}
