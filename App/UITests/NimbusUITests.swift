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
        // Forces sample data so the demo is identical and runs offline.
        app.launchArguments += ["-NimbusSampleData"]
        app.launch()

        // Forecast, then down through hourly, 10-day and tiles.
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 20))
        // Let any first-boot system banner clear before recording starts.
        beat(5)
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
        // Drag across the header, since the hourly strip below scrolls sideways too.
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.2))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.2))
        from.press(forDuration: 0.1, thenDragTo: to)
        beat(2.5)
        to.press(forDuration: 0.1, thenDragTo: from)
        beat()

        // Locations list, search, add, open.
        app.buttons["Locations"].tap()
        beat(2)
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Tokyo")
        // Live search returns Tokyo; sample data ignores the query and returns canned cities.
        let tokyo = app.buttons.containing(.staticText, identifier: "Tokyo").firstMatch
        let oslo = app.buttons.containing(.staticText, identifier: "Oslo").firstMatch
        let deadline = Date().addingTimeInterval(8)
        while !tokyo.exists && !oslo.exists && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.25)
        }
        beat()
        let result = tokyo.exists ? tokyo : oslo
        XCTAssertTrue(result.exists)
        result.tap()
        beat(3)

        // Units toggle: back in the list, switch to Celsius.
        app.buttons["Locations"].tap()
        beat(2)
        let units = app.buttons["units-menu"]
        if units.waitForExistence(timeout: 5) {
            units.tap()
            beat()
            app.buttons["Celsius"].firstMatch.tap()
            beat(3)
        }
    }
}
