import Testing
import NimbusCore

@Suite("TemperatureRangeBar")
struct TemperatureRangeBarTests {
    @Test func positionsBarWithinWeekRange() {
        let layout = TemperatureRangeBar.layout(low: 10, high: 20, weekLow: 0, weekHigh: 40, current: 15)
        #expect(layout.start == 0.25)
        #expect(layout.end == 0.5)
        #expect(layout.marker == 0.375)
    }

    @Test func fullWeekSpanFillsTrack() {
        let layout = TemperatureRangeBar.layout(low: 0, high: 40, weekLow: 0, weekHigh: 40)
        #expect(layout == RangeBarLayout(start: 0, end: 1, marker: nil))
    }

    @Test func equalWeekBoundsGiveFullWidthBar() {
        let layout = TemperatureRangeBar.layout(low: 5, high: 5, weekLow: 5, weekHigh: 5, current: 5)
        #expect(layout.start == 0)
        #expect(layout.end == 1)
        #expect(layout.marker == 0.5)
    }

    @Test func equalWeekBoundsWithoutCurrentHaveNoMarker() {
        let layout = TemperatureRangeBar.layout(low: 5, high: 5, weekLow: 5, weekHigh: 5)
        #expect(layout.marker == nil)
    }

    @Test(arguments: [
        (low: -20.0, high: 50.0, start: 0.0, end: 1.0),
        (low: -20.0, high: 10.0, start: 0.0, end: 0.5),
        (low: 10.0, high: 50.0, start: 0.5, end: 1.0),
    ])
    func outOfRangeValuesClamp(low: Double, high: Double, start: Double, end: Double) {
        let layout = TemperatureRangeBar.layout(low: low, high: high, weekLow: 0, weekHigh: 20)
        #expect(layout.start == start)
        #expect(layout.end == end)
    }

    @Test(arguments: [-5.0, 100.0])
    func outOfRangeMarkerClamps(current: Double) throws {
        let layout = TemperatureRangeBar.layout(low: 0, high: 20, weekLow: 0, weekHigh: 20, current: current)
        let marker = try #require(layout.marker)
        #expect((0...1).contains(marker))
    }

    @Test func endNeverPrecedesStart() {
        let layout = TemperatureRangeBar.layout(low: 15, high: 5, weekLow: 0, weekHigh: 20)
        #expect(layout.end >= layout.start)
    }
}
