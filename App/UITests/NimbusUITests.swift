import XCTest

/// Drives the app like a person for the README demo video. Run through `scripts/record-demo.sh`.
final class NimbusUITests: XCTestCase {
    /// Short pause so each step reads on video.
    private func beat(_ seconds: TimeInterval = 1.5) {
        Thread.sleep(forTimeInterval: seconds)
    }

    @MainActor
    func testDemoTour() throws {
        let app = XCUIApplication()
        // Asks the app to use sample data when live data is unavailable.
        app.launchArguments += ["-NimbusSampleData"]
        app.launch()

        // Forecast, then down through hourly, 10-day and tiles.
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 20))
        // Tells scripts/record-demo.sh to start recording, so the video skips launch time.
        FileManager.default.createFile(atPath: "/tmp/nimbus-demo-ready", contents: nil)
        beat(4)
        for _ in 0..<4 {
            scroll.swipeUp(velocity: .slow)
            beat()
        }
        for _ in 0..<4 {
            scroll.swipeDown(velocity: .fast)
        }
        beat()

        // Next city page and back.
        app.swipeLeft()
        beat(2.5)
        app.swipeRight()
        beat()

        // Locations list, search, add, open.
        app.buttons["Locations"].tap()
        beat(2)
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Tokyo")
        beat(2)
        // Sample data ignores the query, so fall back to a canned result.
        let result = ["Tokyo", "Oslo"]
            .map { app.buttons.containing(.staticText, identifier: $0).firstMatch }
            .first { $0.waitForExistence(timeout: 5) }
        XCTAssertNotNil(result)
        result?.tap()
        beat(3)

        // Units toggle: back in the list, switch to Celsius.
        app.buttons["Locations"].tap()
        beat(2)
        let units = app.buttons["units-menu"]
        if units.waitForExistence(timeout: 5) {
            units.tap()
            beat()
            app.buttons["Celsius"].firstMatch.tap()
            beat(2)
        }
    }
}
