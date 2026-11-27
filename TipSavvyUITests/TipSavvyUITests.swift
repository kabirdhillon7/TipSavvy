//
//  TipSavvyUITests.swift
//  TipSavvyUITests
//
//  Created by Kabir Dhillon on 5/14/23.
//

import XCTest

final class TipSavvyUITests: XCTestCase {
    
    override func setUpWithError() throws {
        // Each test launches its own isolated app via launchIsolatedUITestApp().
        continueAfterFailure = false
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    // naming test_[UI Comp]_[expected result]
    
    func test_contentView_shouldCancelSaving() {
        let app = launchIsolatedUITestApp()
        enterBillAmount("25", in: app)
        app.buttons["Save Tip Calculation"].tap()
        XCTAssertTrue(app.navigationBars["Save Tip"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
    }
    
    func test_enterbillAmountTextField_shouldAcceptInput() {
        let app = launchIsolatedUITestApp()

        let field = app.textFields["Enter Bill Amount"]
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        field.typeText("24")
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        field.typeText("5.5")

        XCTAssertEqual(field.value as? String, "25.5")
    }
    
    func test_slider_shouldTapAndSwipeRight() {
        let app = launchIsolatedUITestApp()
        
        let tipPercentageSelectionSlider = app.sliders["Tip Percentage Selection"]
        tipPercentageSelectionSlider.tap()
        tipPercentageSelectionSlider.swipeRight()
        tipPercentageSelectionSlider.swipeRight()
    }
    
    func test_stepper_shouldAdjustNumberOfPeople() {
        let app = launchIsolatedUITestApp()
        
        app.buttons["Increase People"].tap()
        app.buttons["Decrease People"].tap()
    }

    func test_tipPreset_shouldSelectTwentyPercent() {
        let app = launchIsolatedUITestApp()

        tapScrolledIntoView(app.buttons["20%"], in: app)
        XCTAssertTrue(app.buttons["20%"].isSelected)
    }

    func test_tipComparison_shouldAppearAndApplyPreset() {
        let app = launchIsolatedUITestApp()

        enterBillAmount("42", in: app)

        XCTAssertTrue(app.otherElements["Tip Comparison"].waitForExistence(timeout: 2))
        tapScrolledIntoView(app.buttons["25%"], in: app)

        XCTAssertTrue(app.buttons["25%"].isSelected)
    }

    func test_calculatorAccessibilityElements_shouldBeDiscoverable() {
        let app = launchIsolatedUITestApp(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL",
            "-UIAccessibilityReduceMotionEnabled", "YES"
        ])

        XCTAssertTrue(app.textFields["Enter Bill Amount"].exists, "Enter Bill Amount")
        XCTAssertTrue(app.otherElements["Number of People"].exists, "Number of People")
        XCTAssertTrue(app.buttons["Tip Service Context"].exists, "Tip Service Context")
        XCTAssertTrue(app.buttons["15%"].exists, "15%")
        XCTAssertTrue(app.sliders["Tip Percentage Selection"].exists, "Tip Percentage Selection")
        XCTAssertTrue(app.buttons["Save Tip Calculation"].exists, "Save Tip Calculation")
        XCTAssertTrue(app.buttons["Reset"].exists, "Reset")
        XCTAssertTrue(app.buttons["Copy Menu"].exists, "Copy Menu")
        XCTAssertTrue(app.otherElements["Bill Totals Summary"].exists, "Bill Totals Summary")
        XCTAssertTrue(app.otherElements["Tip Comparison"].exists, "Tip Comparison")
    }

    func test_tipContext_shouldUpdateVisiblePresets() {
        let app = launchIsolatedUITestApp()

        selectTipContext("Delivery", in: app)

        XCTAssertTrue(app.buttons["15%"].exists)
        XCTAssertTrue(app.buttons["18%"].exists)
        XCTAssertTrue(app.buttons["20%"].exists)
        XCTAssertFalse(app.buttons["25%"].exists)
    }

    func test_tipContextCoffee_shouldUpdateComparisonRows() {
        let app = launchIsolatedUITestApp()

        enterBillAmount("42", in: app)
        selectTipContext("Coffee", in: app)

        XCTAssertTrue(app.otherElements["Tip Comparison"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["10%"].exists)
        XCTAssertTrue(app.buttons["15%"].exists)
        XCTAssertTrue(app.buttons["20%"].exists)
    }

    func test_tipContextPreset_shouldApplySelectedPercentage() {
        let app = launchIsolatedUITestApp()

        selectTipContext("Movers", in: app)
        tapScrolledIntoView(app.buttons["5%"], in: app)

        XCTAssertTrue(app.buttons["5%"].isSelected)
    }

    func test_settings_shouldExposeDefaultsAndQualitySignals() {
        let app = launchIsolatedUITestApp()

        selectTab("Settings", in: app)

        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.sliders["Default Tip"].exists)
        XCTAssertTrue(app.switches["Haptic Feedback"].exists)
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Rate on the App Store"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Contact Support"].exists)

        // Form rows below the fold are created lazily.
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Currency"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["About TipSavvy"].exists)
        XCTAssertTrue(app.buttons["Reset Preferences"].exists)
    }

    func test_settingsPrivacyPolicy_shouldOpenAndDismiss() {
        let app = launchIsolatedUITestApp()

        selectTab("Settings", in: app)
        app.buttons["Privacy Policy"].tap()

        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 5))
        let close = app.buttons["Close"].exists ? app.buttons["Close"] : app.buttons["Done"]
        close.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }

    func test_tipPreset_shouldPersistAfterRelaunch() {
        let app = launchIsolatedUITestApp()

        tapScrolledIntoView(app.buttons["20%"], in: app)
        relaunchKeepingState(app)

        XCTAssertTrue(app.buttons["20%"].isSelected)
    }

    func test_stepper_shouldPersistPeopleCountAfterRelaunch() {
        let app = launchIsolatedUITestApp()

        app.buttons["Increase People"].tap()
        relaunchKeepingState(app)

        XCTAssertTrue(app.staticTexts["2"].exists)
    }
    
    func test_tabBar_shouldSelectSavedTab() {
        let app = launchIsolatedUITestApp()
        
        selectTab("Calculate", in: app)
        selectTab("Saved", in: app)
    }
    
    func test_resetButton_shouldResetAndOfferUndo() {
        let app = launchIsolatedUITestApp()

        XCTAssertFalse(app.buttons["Reset"].isEnabled)
        enterBillAmount("25", in: app)
        XCTAssertTrue(app.buttons["Reset"].isEnabled)

        app.buttons["Reset"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["Undo Banner"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Save Tip Calculation"].isEnabled)
    }
    
    func test_saveTipCalculationButton_shouldBeDisabledForInvalidCalculation() {
        let app = launchIsolatedUITestApp()
        
        XCTAssertFalse(app.buttons["Save Tip Calculation"].isEnabled)
    }
    
    func test_saveTipCalculationButton_shouldSave() {
        let app = launchIsolatedUITestApp()

        enterBillAmount("25", in: app)

        app.buttons["Save Tip Calculation"].tap()
        XCTAssertTrue(app.navigationBars["Save Tip"].waitForExistence(timeout: 2))
        replaceText(in: app.textFields["Enter Tip Calculation Name"], with: "Lunch")
        app.buttons["Save"].tap()
    }
    
    func test_saveTipCalculationButton_shouldCancel() {
        let app = launchIsolatedUITestApp()

        enterBillAmount("25", in: app)
        app.buttons["Save Tip Calculation"].tap()
        XCTAssertTrue(app.navigationBars["Save Tip"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
    }

    func test_taxDetailsAndReceiptNote_shouldSaveAndAppearInSavedDetail() {
        let app = launchIsolatedUITestApp()

        enterBillAmount("100", in: app)
        enterTaxAmount("8", in: app)

        app.buttons["Save Tip Calculation"].tap()
        XCTAssertTrue(app.navigationBars["Save Tip"].waitForExistence(timeout: 2))
        replaceText(in: app.textFields["Enter Tip Calculation Name"], with: "Tax Lunch")
        app.textFields["Receipt Note"].tap()
        app.textFields["Receipt Note"].typeText("Patio table")
        app.buttons["Save"].tap()
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'saved'")).firstMatch.waitForExistence(timeout: 3)

        selectTab("Saved", in: app)
        let savedTip = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Tax Lunch"))
            .firstMatch
        XCTAssertTrue(savedTip.waitForExistence(timeout: 2))
        savedTip.tap()

        XCTAssertTrue(app.descendants(matching: .any)["Tax"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["Receipt Note"].exists)
    }

    func test_savedSearch_shouldFilterByName() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Search Lunch", in: app)
        selectTab("Saved", in: app)
        app.searchFields["Search Names and Notes"].tap()
        app.searchFields["Search Names and Notes"].typeText("Search Lunch")

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Search Lunch")).firstMatch.exists)
    }

    func test_savedControls_shouldExposeSortAndFilter() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Filter Dinner", in: app)
        selectTab("Saved", in: app)

        let options = app.buttons["Saved Tips Options"]
        XCTAssertTrue(options.exists)
        options.tap()
        XCTAssertTrue(app.buttons["Newest"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Name"].exists)
        XCTAssertTrue(app.buttons["Recent"].exists)
        app.buttons["Recent"].tap()

        XCTAssertTrue(app.staticTexts["Visible Saved Tips"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Filter Dinner")).firstMatch.exists)
    }

    func test_savedInsights_shouldAppearWhenTipsExist() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Insight Dinner", in: app)
        selectTab("Saved", in: app)

        let insights = app.buttons["Saved Insights"]
        XCTAssertTrue(insights.waitForExistence(timeout: 2))
        XCTAssertEqual(insights.label, "Spent This Month")
        XCTAssertTrue((insights.value as? String)?.contains("in tips") == true)
        XCTAssertFalse(app.staticTexts["Total Saved"].exists)
        XCTAssertFalse(app.staticTexts["Average Tip"].exists)
        XCTAssertFalse(app.staticTexts["Most Common Split"].exists)
        XCTAssertFalse(app.staticTexts["Largest Saved Bill"].exists)
    }

    func test_savedInsights_shouldHideWhenNoTipsExist() {
        let app = launchIsolatedUITestApp()

        selectTab("Saved", in: app)

        XCTAssertTrue(app.staticTexts["No Saved Tips"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Saved Insights"].exists)
    }

    func test_savedInsights_shouldRemainVisibleWhenSearchHasNoMatches() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Visible Insight Dinner", in: app)
        selectTab("Saved", in: app)
        app.searchFields["Search Names and Notes"].tap()
        app.searchFields["Search Names and Notes"].typeText("No Results Expected")

        XCTAssertTrue(app.buttons["Saved Insights"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["No Matching Tips"].waitForExistence(timeout: 2))
    }

    func test_savedInsights_shouldOpenDetailSheetAndDismiss() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Insight Detail Dinner", in: app)
        selectTab("Saved", in: app)
        app.buttons["Saved Insights"].tap()

        XCTAssertTrue(app.navigationBars["Saved Insights"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["Saved Insights Spending Chart"].exists)
        XCTAssertTrue(app.staticTexts["Saved Insights This Month"].exists)
        XCTAssertTrue(app.otherElements["Saved Insights All Time"].exists)
        XCTAssertTrue(app.otherElements["Saved Insights Highlights"].exists)

        app.buttons["Done"].tap()

        XCTAssertTrue(app.navigationBars["Saved Tips"].waitForExistence(timeout: 2))
    }

    func test_savedSearch_shouldShowNoMatchingTips() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Findable Dinner", in: app)
        selectTab("Saved", in: app)
        app.searchFields["Search Names and Notes"].tap()
        app.searchFields["Search Names and Notes"].typeText("No Results Expected")

        XCTAssertTrue(app.staticTexts["No Matching Tips"].exists)
    }

    func test_savedRename_shouldUpdateDisplayedName() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Rename Dinner", in: app)
        selectTab("Saved", in: app)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Rename Dinner")).firstMatch.press(forDuration: 1)
        app.buttons["Rename"].tap()
        let renameField = app.alerts["Rename Saved Tip"].textFields["Enter Name"]
        renameField.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        renameField.typeText(" Updated")
        app.alerts["Rename Saved Tip"].buttons["OK"].tap()

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Rename Dinner Updated")).firstMatch.exists)
    }

    func test_savedRowAccessibilitySummary_shouldBeDiscoverable() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Accessible Dinner", in: app)
        selectTab("Saved", in: app)

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Accessible Dinner")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Per Person")).firstMatch.exists)
    }

    func test_savedCard_shouldOpenDetailSheet() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Sheet Dinner", in: app)
        selectTab("Saved", in: app)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Sheet Dinner")).firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Saved Tip Details"].exists)
        XCTAssertTrue(app.buttons["Use Saved Tip Again"].exists)
        XCTAssertTrue(app.buttons["Share"].exists)
        app.buttons["Saved Tip More"].tap()
        XCTAssertTrue(app.buttons["Rename"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Delete"].exists)
    }

    func test_savedDetailUseAgain_shouldReturnToCalculatorWithSavedInputs() {
        let app = launchIsolatedUITestApp()

        enterBillAmount("25", in: app)
        tapScrolledIntoView(app.buttons["20%"], in: app)
        app.buttons["Increase People"].tap()
        saveCurrentTip(named: "Reuse Dinner", in: app)
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'saved'")).firstMatch.waitForExistence(timeout: 3)

        selectTab("Saved", in: app)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Reuse Dinner")).firstMatch.tap()
        app.buttons["Use Saved Tip Again"].tap()

        XCTAssertTrue(app.navigationBars["TipSavvy"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["20%"].isSelected)
        XCTAssertEqual(app.otherElements["Number of People"].value as? String, "2")
    }

    func test_calculateRoundCopySaveAndOpenDetail_shouldCompletePrimaryFlow() {
        let app = launchIsolatedUITestApp()

        enterBillAmount("25", in: app)
        tapScrolledIntoView(app.buttons["20%"], in: app)
        app.buttons["Increase People"].tap()
        tapScrolledIntoView(app.buttons["Total Up"], in: app)

        XCTAssertTrue(app.staticTexts["Rounding Explanation"].waitForExistence(timeout: 2))

        app.buttons["Copy Menu"].tap()
        app.buttons["Copy Per Person"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Success Banner"].waitForExistence(timeout: 2))

        saveCurrentTip(named: "E2E Dinner", in: app)
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'saved'")).firstMatch.waitForExistence(timeout: 3)

        selectTab("Saved", in: app)
        let savedTip = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "E2E Dinner")).firstMatch
        XCTAssertTrue(savedTip.waitForExistence(timeout: 2))
        savedTip.tap()

        XCTAssertTrue(app.navigationBars["Saved Tip Details"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Share"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Saved Tip Receipt"].exists)
    }
    
    func test_keyboardDoneButton_shouldDimissKeyboard() {
        let app = launchIsolatedUITestApp()
        app.textFields["Enter Bill Amount"].tap()
        app.toolbars["Toolbar"].buttons["Done"].tap()
    }

    private func enterBillAmount(_ amount: String, in app: XCUIApplication) {
        let enterBillAmountTextField = app.textFields["Enter Bill Amount"]
        enterBillAmountTextField.tap()
        enterBillAmountTextField.typeText(amount)
        app.toolbars["Toolbar"].buttons["Done"].tap()
    }

    private func saveTip(named name: String, in app: XCUIApplication) {
        selectTab("Calculate", in: app)
        enterBillAmount("25", in: app)
        saveCurrentTip(named: name, in: app)
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'saved'")).firstMatch.waitForExistence(timeout: 3)
    }

    private func saveCurrentTip(named name: String, in app: XCUIApplication) {
        app.buttons["Save Tip Calculation"].tap()
        XCTAssertTrue(app.navigationBars["Save Tip"].waitForExistence(timeout: 2))
        replaceText(in: app.textFields["Enter Tip Calculation Name"], with: name)
        app.buttons["Save"].tap()
    }

    private func enterTaxAmount(_ amount: String, in app: XCUIApplication) {
        let toggle = app.buttons["Tax Details Toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        if !toggle.isHittable {
            app.scrollViews.firstMatch.swipeDown()
        }
        toggle.tap()
        let taxField = app.textFields["Optional Tax Amount"]
        XCTAssertTrue(taxField.waitForExistence(timeout: 2))
        taxField.tap()
        taxField.typeText(amount)
        app.toolbars["Toolbar"].buttons["Done"].tap()
    }

    /// The tab bar minimizes on scroll and then shows only the current tab,
    /// so scroll back up (or tap the collapsed bar) to reveal the others.
    private func selectTab(_ name: String, in app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))
        if !tabBar.buttons[name].exists {
            app.scrollViews.firstMatch.swipeDown()
        }
        if !tabBar.buttons[name].exists {
            tabBar.buttons.firstMatch.tap()
        }
        XCTAssertTrue(tabBar.buttons[name].waitForExistence(timeout: 2), "Tab \(name)")
        tabBar.buttons[name].tap()
    }

    /// Replaces a text field's contents. Fields can arrive pre-filled (the save sheet
    /// suggests a name), and typing would otherwise append to it.
    private func replaceText(in field: XCUIElement, with text: String) {
        field.tap()
        if let current = field.value as? String, !current.isEmpty, current != field.placeholderValue {
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }

    /// The tab bar floats over content, and XCUITest's own scroll-to-visible ignores it,
    /// so scroll until the element sits clear of the bar before tapping.
    private func tapScrolledIntoView(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 2))
        let tabBar = app.tabBars.firstMatch
        var attempts = 0
        while attempts < 4,
              !element.isHittable || (tabBar.exists && element.frame.maxY > tabBar.frame.minY - 8) {
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
            attempts += 1
        }
        element.tap()
    }

    /// Every test launches with `-ui-testing`: an in-memory store and freshly reset defaults,
    /// so state never leaks between tests or runs.
    private func launchIsolatedUITestApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launchArguments += ["-AppleLanguages", "(en-US)"]
        app.launchArguments += ["-AppleLocale", "\"en-US\""]
        app.launchArguments += extraArguments
        app.terminate()
        app.launch()
        return app
    }

    /// Relaunches without resetting defaults, to check that preferences persist.
    private func relaunchKeepingState(_ app: XCUIApplication) {
        app.terminate()
        app.launchArguments += ["-ui-testing-keep-defaults"]
        app.launch()
    }


    private func selectTipContext(_ context: String, in app: XCUIApplication) {
        let contextButton = app.buttons["Tip Service Context"]
        if !contextButton.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        contextButton.tap()
        app.buttons[context].tap()
    }
}
