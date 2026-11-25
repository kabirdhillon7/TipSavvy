//
//  AppStoreScreenshotTests.swift
//  TipSavvyUITests
//
//  Created by Codex on 5/8/26.
//

import XCTest

/// Captures the App Store screenshot set ("Enter the bill, pick the tip, split it fairly, and save it.").
///
/// Each test launches straight into a prepared state with `-app-store-screenshot <mode>` so values
/// are exact: the calculator mode fills in an $86.40 bill, 20% tip, 3 people and Person Up rounding.
/// Run on the iPhone 6.9", iPad 13" and iPhone Duo simulators, then export the attachments.
final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test01EnterTheBill() throws {
        launch(mode: "calculator")

        let billAmountField = app.textFields["Enter Bill Amount"]
        XCTAssertTrue(billAmountField.waitForExistence(timeout: 2))
        billAmountField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        // The keypad exists before it finishes sliding up; wait so the capture shows it.
        Thread.sleep(forTimeInterval: 1.5)
        capture("01-enter-the-bill")
    }

    func test02PickTheTip() throws {
        launch(mode: "calculator")

        XCTAssertTrue(app.textFields["Enter Bill Amount"].waitForExistence(timeout: 2))
        app.swipeUp()
        XCTAssertTrue(app.buttons["Person Up"].waitForExistence(timeout: 2))
        capture("02-pick-the-tip")
    }

    func test03SplitItFairly() throws {
        launch(mode: "calculator")

        XCTAssertTrue(app.textFields["Enter Bill Amount"].waitForExistence(timeout: 2))
        capture("03-split-it-fairly")
    }

    func test04SaveIt() throws {
        launch(mode: "saved")

        XCTAssertTrue(app.navigationBars["Saved Tips"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Dinner")).firstMatch.waitForExistence(timeout: 2))
        capture("04-save-it")
    }

    private func launch(mode: String) {
        app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-demo-data",
            "-app-store-screenshot", mode,
            "-AppleLanguages", "(en-US)",
            "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL",
            "-UIAccessibilityReduceMotionEnabled", "YES"
        ]
        app.launch()
        // App Store screenshots are portrait; don't depend on how the simulator was left.
        XCUIDevice.shared.orientation = .portrait
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: screenToCapture().screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// `XCUIScreen.main` is the outer screen on iPhone Duo. When the capture script sets
    /// SCREENSHOT_SCREEN=largest (unfolded Duo), capture the inner screen instead.
    private func screenToCapture() -> XCUIScreen {
        guard ProcessInfo.processInfo.environment["SCREENSHOT_SCREEN"] == "largest" else {
            return XCUIScreen.main
        }
        return XCUIScreen.screens.max { lhs, rhs in
            let l = lhs.screenshot().image.size, r = rhs.screenshot().image.size
            return l.width * l.height < r.width * r.height
        } ?? XCUIScreen.main
    }
}
