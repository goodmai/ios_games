import XCTest

/// Integration UI tests — drive the real `MorseLight` app through the view layer
/// on a simulator. These run in CI (unit tests run locally on Mac per project
/// convention). XCUITest requires `XCTestCase`, so these intentionally use XCTest
/// rather than Swift Testing.
final class MorseLightUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchApp(_ extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"] + extraArgs
        app.launch()
        return app
    }

    // MARK: - App shell

    func testMainScreenReachableAndShowsMessageField() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["MorseLight"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.textViews["messageField"].exists || app.textFields["messageField"].exists)
    }

    func testTypingMessageUpdatesMorsePreview() {
        let app = launchApp()
        let field = app.textViews["messageField"].exists
            ? app.textViews["messageField"]
            : app.textFields["messageField"]
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        field.tap()
        field.typeText("SOS")

        let preview = app.staticTexts["morsePreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        XCTAssertEqual(preview.label, "... --- ...")
    }

    func testAutoTuneToggleExistsAndToggles() {
        let app = launchApp()
        let toggle = app.switches["autoTuneToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 15))
        let before = toggle.value as? String
        toggle.tap()
        XCTAssertNotEqual(before, toggle.value as? String)
    }

    // MARK: - Epic E1 + E2: end-to-end decode round-trip through the live pipeline

    func testDecodeSelfTestRoundTripsSOS() {
        let app = launchApp(["-decodeSelfTest"])
        let decoded = app.staticTexts["decodedText"]
        XCTAssertTrue(decoded.waitForExistence(timeout: 30))
        XCTAssertEqual(decoded.label, "SOS")
    }

    func testDecodeSelfTestWithAutoTuneRoundTripsSOS() {
        let app = launchApp(["-decodeSelfTest", "-autoTune"])
        let decoded = app.staticTexts["decodedText"]
        XCTAssertTrue(decoded.waitForExistence(timeout: 30))
        XCTAssertEqual(decoded.label, "SOS")
    }
}
</content>
