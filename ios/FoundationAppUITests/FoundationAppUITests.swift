import XCTest

final class FoundationAppUITests: XCTestCase {
    @MainActor
    func testLaunches() {
        let app = XCUIApplication()
        app.launchEnvironment["APP_ROOT_URL"] = "http://127.0.0.1:1"
        app.launch()

        XCTAssertEqual(app.state, .runningForeground)
    }
}
