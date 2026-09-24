import XCTest

final class GeneratedApplicationNavigationUITests: XCTestCase {
    @MainActor
    func testUsesOneEntryWithoutATabBar() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["APP_ROOT_URL"] = "http://127.0.0.1:1"
        app.launch()

        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }
}
