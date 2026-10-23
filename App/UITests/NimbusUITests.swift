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
        let addedName = tokyo.exists ? "Tokyo" : "Oslo"
        result.tap()
        beat(3)
        // The search closes onto the new place's page; a broken add leaves the sheet open.
        XCTAssertFalse(app.searchFields.firstMatch.exists, "search sheet should close after picking a result")
        XCTAssertTrue(app.staticTexts[addedName].waitForExistence(timeout: 5), "added place should open as a page")

        // Units toggle: back in the list, which now includes the added place, switch to Celsius.
        app.buttons["Locations"].tap()
        beat(2)
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: addedName).firstMatch.exists,
                      "added place should be in the saved list")
        let units = app.buttons["units-menu"]
        if units.waitForExistence(timeout: 5) {
            units.tap()
            beat()
            app.buttons["Celsius"].firstMatch.tap()
            beat(3)
        }
    }

    /// Tapping blank space in a search result row, away from its text, must still add and open the place.
    @MainActor
    func testAddPlaceFromSearchTapsWholeRow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-NimbusSampleData"]
        app.launch()
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 20))

        app.buttons["Locations"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Oslo")

        // Sample data returns Cupertino (already saved) and Oslo (new), whatever the query.
        let row = app.buttons.containing(.staticText, identifier: "Oslo").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 8))
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()

        // The sheet closes onto Oslo's page.
        XCTAssertTrue(app.staticTexts["Oslo"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.searchFields.firstMatch.exists)

        // And Oslo is in the saved list.
        app.buttons["Locations"].tap()
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: "Oslo").firstMatch.waitForExistence(timeout: 5))
    }
}
