import Testing
import NimbusCore

@Suite("WeatherCondition")
struct WeatherConditionTests {
    @Test(arguments: [
        (0, WeatherCondition.clear), (1, .mainlyClear), (2, .partlyCloudy), (3, .overcast),
        (45, .fog), (48, .fog), (51, .drizzle), (55, .drizzle), (56, .freezingDrizzle),
        (61, .rain), (65, .heavyRain), (66, .freezingRain), (71, .snow), (75, .heavySnow),
        (77, .snowGrains), (80, .rainShowers), (82, .rainShowers), (85, .snowShowers),
        (95, .thunderstorm), (96, .thunderstormWithHail), (99, .thunderstormWithHail),
    ])
    func mapsWMOCode(code: Int, expected: WeatherCondition) {
        #expect(WeatherCondition(wmoCode: code) == expected)
    }

    @Test(arguments: [-1, 4, 44, 60, 100, 1000])
    func unrecognizedCodeIsUnknown(code: Int) {
        #expect(WeatherCondition(wmoCode: code) == .unknown)
    }

    @Test(arguments: WeatherCondition.allCases)
    func everyCaseHasSymbolsAndName(condition: WeatherCondition) {
        #expect(!condition.symbolName(isDaylight: true).isEmpty)
        #expect(!condition.symbolName(isDaylight: false).isEmpty)
        #expect(!condition.displayName.isEmpty)
    }

    @Test func clearSkySymbolDependsOnDaylight() {
        #expect(WeatherCondition.clear.symbolName(isDaylight: true) == "sun.max.fill")
        #expect(WeatherCondition.clear.symbolName(isDaylight: false) == "moon.stars.fill")
    }
}
