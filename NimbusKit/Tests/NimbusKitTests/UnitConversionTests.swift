import Testing
import NimbusCore

@Suite("UnitConversion")
struct UnitConversionTests {
    @Test(arguments: [
        (celsius: 0.0, fahrenheit: 32.0),
        (celsius: 100.0, fahrenheit: 212.0),
        (celsius: -40.0, fahrenheit: -40.0),
        (celsius: 37.0, fahrenheit: 98.6),
    ])
    func celsiusToFahrenheit(celsius: Double, fahrenheit: Double) {
        #expect(abs(UnitConversion.temperature(celsius: celsius, to: .fahrenheit) - fahrenheit) < 1e-9)
    }

    @Test(arguments: [-12.5, 0, 21.3])
    func celsiusIsIdentity(celsius: Double) {
        #expect(UnitConversion.temperature(celsius: celsius, to: .celsius) == celsius)
    }

    @Test func kilometersPerHourToMilesPerHour() {
        #expect(abs(UnitConversion.speed(kmh: 100, to: .milesPerHour) - 62.1371) < 1e-3)
        #expect(UnitConversion.speed(kmh: 100, to: .kilometersPerHour) == 100)
    }

    @Test func visibility() {
        #expect(UnitConversion.visibility(meters: 10_000, imperial: false) == 10)
        #expect(abs(UnitConversion.visibility(meters: 1609.344, imperial: true) - 1) < 1e-9)
    }

    @Test func precipitation() {
        #expect(UnitConversion.precipitation(mm: 25.4, imperial: false) == 25.4)
        #expect(abs(UnitConversion.precipitation(mm: 25.4, imperial: true) - 1) < 1e-9)
    }

    @Test func pressure() {
        #expect(UnitConversion.pressure(hPa: 1013, imperial: false) == 1013)
        #expect(abs(UnitConversion.pressure(hPa: 1013.25, imperial: true) - 29.92) < 0.01)
    }
}
