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
        switch condition {
        case .clear, .mainlyClear, .partlyCloudy, .unknown:
            self = isDaylight ? .clearDay : .clearNight
        case .overcast:
            self = isDaylight ? .cloudyDay : .cloudyNight
        case .fog:
            self = isDaylight ? .fogDay : .fogNight
        case .drizzle, .freezingDrizzle, .rain, .heavyRain, .freezingRain, .rainShowers:
            self = isDaylight ? .rainDay : .rainNight
        case .snow, .heavySnow, .snowGrains, .snowShowers:
            self = isDaylight ? .snowDay : .snowNight
        case .thunderstorm, .thunderstormWithHail:
            self = isDaylight ? .stormDay : .stormNight
        }
    }

    /// Vertical gradient stops, top to bottom, at least two.
    public var gradient: [PaletteColor] {
        let hexes: [UInt32] = switch self {
        case .clearDay: [0x2F80D8, 0x5BA9F0, 0x9CCBF5]
        case .clearNight: [0x0B1535, 0x16275A, 0x2B3F7A]
        case .cloudyDay: [0x5F7A94, 0x8499AF, 0xA9B8C7]
        case .cloudyNight: [0x1F2733, 0x2F3A49, 0x445263]
        case .rainDay: [0x3F5568, 0x5B7186, 0x7F93A5]
        case .rainNight: [0x141B26, 0x232F3E, 0x354558]
        case .snowDay: [0x7E94AB, 0xA6B8CA, 0xCFDAE5]
        case .snowNight: [0x2A3547, 0x44546B, 0x65778F]
        case .stormDay: [0x2E3441, 0x464D5E, 0x636B7C]
        case .stormNight: [0x0C0F18, 0x1A1F2E, 0x2D3446]
        case .fogDay: [0x8A97A3, 0xA9B3BC, 0xC8CFD5]
        case .fogNight: [0x2A3038, 0x3C444E, 0x545E69]
        }
        return hexes.map { PaletteColor(hex: $0) }
    }

    public var isNight: Bool {
        switch self {
        case .clearNight, .cloudyNight, .rainNight, .snowNight, .stormNight, .fogNight: true
        default: false
        }
    }
}
