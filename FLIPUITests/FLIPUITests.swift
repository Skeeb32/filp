import XCTest

final class FLIPUITests: XCTestCase {
    func testCapturePersistsAndNavigationWorks() throws {
        let app = XCUIApplication(); app.launch()
        app.buttons["capture"].tap()
        let title = app.descendants(matching: .any)["itemTitle"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let unique = "UI capture " + UUID().uuidString.prefix(8)
        title.tap(); title.typeText(unique)
        app.buttons["saveItem"].tap()
        let search = app.textFields["search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText(unique)
        XCTAssertTrue(app.staticTexts[unique].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        let restoredSearch = app.textFields["search"]
        XCTAssertTrue(restoredSearch.waitForExistence(timeout: 5))
        restoredSearch.tap(); restoredSearch.typeText(unique)
        XCTAssertTrue(app.staticTexts[unique].waitForExistence(timeout: 5))
        app.buttons["tabFocus"].tap()
        XCTAssertTrue(app.staticTexts["One thing at a time."].waitForExistence(timeout: 5))
        app.buttons["tabLife"].tap()
        XCTAssertTrue(app.staticTexts["A life, well lived."].waitForExistence(timeout: 5))
        app.buttons["tabCalendar"].tap()
        XCTAssertTrue(app.staticTexts["Time, on your terms."].waitForExistence(timeout: 5))
        app.buttons["tabAI"].tap()
        XCTAssertTrue(app.staticTexts["A clearer headspace."].waitForExistence(timeout: 5))
    }
    func testFocusAndCalendarControls() {
        let app = XCUIApplication(); app.launch()
        app.buttons["tabFocus"].tap()
        let begin = app.buttons["Begin focus"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5)); begin.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5)); app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5)); app.buttons["Resume"].tap()
        app.buttons["End"].tap()
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        app.buttons["tabCalendar"].tap()
        app.buttons["Next period"].tap()
        app.buttons["Back to today"].tap()
        app.buttons["Week"].tap()
        XCTAssertTrue(app.buttons["Previous period"].exists)
    }
    func testWorkspaceSelection() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(); app.launch()
        let task = app.staticTexts["Shape the next chapter"]
        XCTAssertTrue(task.waitForExistence(timeout: 5)); task.tap()
        XCTAssertTrue(app.descendants(matching: .any)["itemTitle"].firstMatch.waitForExistence(timeout: 5))
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(app.staticTexts["Make space for what matters"].exists)
            XCTAssertTrue(app.buttons["saveItem"].isHittable)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways; add(attachment)
    }
}
