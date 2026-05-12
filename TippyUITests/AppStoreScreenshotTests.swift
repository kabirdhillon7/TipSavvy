//
//  AppStoreScreenshotTests.swift
//  TippyUITests
//
//  Created by Codex on 5/8/26.
//

import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-demo-data",
            "-AppleLanguages", "(en-US)",
            "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL",
            "-UIAccessibilityReduceMotionEnabled", "YES"
        ]
        app.launch()
    }

    func test01CalculatorReadyToSplit() throws {
        enterBillAmount("86.40")
        app.buttons["20%"].tap()
        app.buttons["Increase People"].tap()
        app.buttons["Increase People"].tap()
        app.buttons["Person Up"].tap()

        XCTAssertTrue(app.otherElements["Bill Totals Summary"].waitForExistence(timeout: 2))
        capture("01-calculator-ready-to-split")
    }

    func test02SavedTipsLibrary() throws {
        selectTab("Saved")

        XCTAssertTrue(app.navigationBars["Saved Tips"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Table")).firstMatch.waitForExistence(timeout: 2))
        capture("02-saved-tips-library")
    }

    func test03SavedTipDetails() throws {
        selectTab("Saved")

        let firstSavedTipName = app.staticTexts["Table 1"]
        XCTAssertTrue(firstSavedTipName.waitForExistence(timeout: 2))
        firstSavedTipName.tap()

        XCTAssertTrue(app.navigationBars["Saved Tip Details"].waitForExistence(timeout: 2))
        capture("03-saved-tip-details")
    }

    func test04SettingsAndPrivacy() throws {
        selectTab("Settings")

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Privacy & Reliability"].waitForExistence(timeout: 2))
        capture("04-settings-and-privacy")
    }

    func test05SettingsSupportAndReadiness() throws {
        selectTab("Settings")

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        app.swipeUp()
        XCTAssertTrue(app.otherElements["About TipSavvy"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Request App Review"].exists)
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        capture("05-settings-support-and-readiness")
    }

    private func enterBillAmount(_ amount: String) {
        let billAmountField = app.textFields["Enter Bill Amount"]
        XCTAssertTrue(billAmountField.waitForExistence(timeout: 2))
        billAmountField.tap()
        billAmountField.typeText(amount)

        let doneButton = app.toolbars["Toolbar"].buttons["Done"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
        }
    }

    private func selectTab(_ label: String) {
        let tabBarButton = app.tabBars["Tab Bar"].buttons[label]
        if tabBarButton.waitForExistence(timeout: 1) {
            tabBarButton.tap()
            return
        }

        let button = app.buttons[label].firstMatch
        if button.waitForExistence(timeout: 2) {
            button.tap()
            return
        }

        let cell = app.cells[label]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        cell.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
