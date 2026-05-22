//
//  TippyUITests.swift
//  TippyUITests
//
//  Created by Kabir Dhillon on 5/14/23.
//

import XCTest

final class TippyUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launchArguments += ["-AppleLanguages", "(en-US)"]
        app.launchArguments += ["-AppleLocale", "\"en-US\""]
        
        app.launch()
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    //    func testExample() throws {
    //        // UI tests must launch the application that they test.
    //        let app = XCUIApplication()
    //        app.launch()
    //
    //        // Use XCTAssert and related functions to verify your tests produce the correct results.
    //    }
    
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
        let app = XCUIApplication()
        enterBillAmount("25", in: app)
        app.buttons["Save Tip Calculation"].tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["Cancel"].tap()
    }
    
    func test_enterbillAmountTextField_shouldAcceptInput() {
        let app = XCUIApplication()
        app.launch()
        
        let enterBillAmountTextField = app.textFields["Enter Bill Amount"]
        enterBillAmountTextField.tap()
        
        app/*@START_MENU_TOKEN@*/.keys["2"]/*[[".keyboards.keys[\"2\"]",".keys[\"2\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["4"]/*[[".keyboards.keys[\"4\"]",".keys[\"4\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["Delete"]/*[[".keyboards.keys[\"Delete\"]",".keys[\"Delete\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["5"]/*[[".keyboards.keys[\"5\"]",".keys[\"5\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func test_slider_shouldTapAndSwipeRight() {
        let app = XCUIApplication()
        app.launch()
        
        let tipPercentageSelectionSlider = app.sliders["Tip Percentage Selection"]
        tipPercentageSelectionSlider.tap()
        tipPercentageSelectionSlider.swipeRight()
        tipPercentageSelectionSlider.swipeRight()
    }
    
    func test_stepper_shouldAdjustNumberOfPeople() {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Increase People"].tap()
        app.buttons["Decrease People"].tap()
    }

    func test_tipPreset_shouldSelectTwentyPercent() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["20%"].tap()
        XCTAssertEqual(app.buttons["20%"].value as? String, "Selected")
    }

    func test_tipComparison_shouldAppearAndApplyPreset() {
        let app = XCUIApplication()
        app.launch()

        enterBillAmount("42", in: app)

        XCTAssertTrue(app.otherElements["Tip Comparison"].waitForExistence(timeout: 2))
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "25% tip comparison")).firstMatch.tap()

        XCTAssertEqual(app.buttons["25%"].value as? String, "Selected")
    }

    func test_calculatorAccessibilityElements_shouldBeDiscoverable() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
        app.launchArguments += ["-UIAccessibilityReduceMotionEnabled", "YES"]
        app.launch()

        XCTAssertTrue(app.textFields["Enter Bill Amount"].exists)
        XCTAssertTrue(app.staticTexts["Number of People"].exists)
        XCTAssertTrue(app.buttons["Tip Service Context"].exists)
        XCTAssertTrue(app.staticTexts["Tip Context Helper"].exists)
        XCTAssertTrue(app.buttons["15%"].exists)
        XCTAssertTrue(app.sliders["Tip Percentage Selection"].exists)
        XCTAssertTrue(app.buttons["Save Tip Calculation"].exists)
        XCTAssertTrue(app.buttons["Reset"].exists)
        XCTAssertTrue(app.otherElements["Bill Totals Summary"].exists)
        XCTAssertTrue(app.otherElements["Tip Comparison"].exists)
    }

    func test_tipContext_shouldUpdateVisiblePresets() {
        let app = XCUIApplication()
        app.launch()

        selectTipContext("Delivery", in: app)

        XCTAssertTrue(app.buttons["15%"].exists)
        XCTAssertTrue(app.buttons["18%"].exists)
        XCTAssertTrue(app.buttons["20%"].exists)
        XCTAssertFalse(app.buttons["25%"].exists)
    }

    func test_tipContextCoffee_shouldUpdateComparisonRows() {
        let app = XCUIApplication()
        app.launch()

        enterBillAmount("42", in: app)
        selectTipContext("Coffee", in: app)

        XCTAssertTrue(app.otherElements["Tip Comparison"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "10% tip comparison")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "15% tip comparison")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "20% tip comparison")).firstMatch.exists)
    }

    func test_tipContextPreset_shouldApplySelectedPercentage() {
        let app = XCUIApplication()
        app.launch()

        selectTipContext("Movers", in: app)
        app.buttons["5%"].tap()

        XCTAssertEqual(app.buttons["5%"].value as? String, "Selected")
    }

    func test_settings_shouldExposeDefaultsAndQualitySignals() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars["Tab Bar"].buttons["Settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.sliders["Default Tip"].exists)
        XCTAssertTrue(app.switches["Haptic Feedback"].exists)
        XCTAssertTrue(app.staticTexts["Currency"].exists)
        XCTAssertTrue(app.buttons["Request App Review"].exists)
        XCTAssertTrue(app.buttons["Rate on the App Store"].exists)
        XCTAssertTrue(app.otherElements["About TipSavvy"].exists)
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        XCTAssertTrue(app.buttons["Contact Support"].exists)
        XCTAssertTrue(app.buttons["Reset Preferences"].exists)
    }

    func test_settingsPrivacyPolicy_shouldOpenAndDismiss() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars["Tab Bar"].buttons["Settings"].tap()
        app.buttons["Privacy Policy"].tap()

        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }

    func test_tipPreset_shouldPersistAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["20%"].tap()
        app.terminate()
        app.launch()

        XCTAssertEqual(app.buttons["20%"].value as? String, "Selected")
    }

    func test_stepper_shouldPersistPeopleCountAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Increase People"].tap()
        app.terminate()
        app.launch()

        XCTAssertTrue(app.staticTexts["2"].exists)
    }
    
    func test_tabBar_shouldSelectSavedTab() {
        let app = XCUIApplication()
        app.launch()
        
        let tabBar = XCUIApplication().tabBars["Tab Bar"]
        tabBar.buttons["Calculate"].tap()
        tabBar.buttons["Saved"].tap()
    }
    
    func test_resetButton_shouldTap() {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Reset"].tap()
    }
    
    func test_saveTipCalculationButton_shouldBeDisabledForInvalidCalculation() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertFalse(app.buttons["Save Tip Calculation"].isEnabled)
    }
    
    func test_saveTipCalculationButton_shouldSave() {
        let app = XCUIApplication()
        app.launch()

        enterBillAmount("25", in: app)

        app.buttons["Save Tip Calculation"].tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.textFields["Enter Name"].typeText("Lunch")
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["OK"].tap()
    }
    
    func test_saveTipCalculationButton_shouldCancel() {
        let app = XCUIApplication()
        app.launch()

        enterBillAmount("25", in: app)
        app.buttons["Save Tip Calculation"].tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["Cancel"].tap()
    }

    func test_savedSearch_shouldFilterByName() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Search Lunch", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].typeText("Search Lunch")

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Search Lunch")).firstMatch.exists)
    }

    func test_savedControls_shouldExposeSortAndFilter() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Filter Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()

        XCTAssertTrue(app.buttons["Saved Tips Filter"].exists)
        XCTAssertTrue(app.buttons["Saved Tips Sort"].exists)
        XCTAssertTrue(app.staticTexts["Newest"].exists)
        XCTAssertTrue(app.staticTexts["All"].exists)
    }

    func test_savedInsights_shouldAppearWhenTipsExist() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Insight Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()

        XCTAssertTrue(app.buttons["Saved Insights"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Spent This Month"].exists)
        XCTAssertTrue(app.staticTexts["Tips This Month"].exists)
        XCTAssertTrue(app.staticTexts["Saved Tips"].exists)
        XCTAssertFalse(app.staticTexts["Total Saved"].exists)
        XCTAssertFalse(app.staticTexts["Average Tip"].exists)
        XCTAssertFalse(app.staticTexts["Most Common Split"].exists)
        XCTAssertFalse(app.staticTexts["Largest Saved Bill"].exists)
    }

    func test_savedInsights_shouldHideWhenNoTipsExist() {
        let app = launchIsolatedUITestApp()

        app.tabBars["Tab Bar"].buttons["Saved"].tap()

        XCTAssertTrue(app.staticTexts["No Saved Tips"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Saved Insights"].exists)
    }

    func test_savedInsights_shouldRemainVisibleWhenSearchHasNoMatches() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Visible Insight Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].typeText("No Results Expected")

        XCTAssertTrue(app.buttons["Saved Insights"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["No Matching Tips"].waitForExistence(timeout: 2))
    }

    func test_savedInsights_shouldOpenDetailSheetAndDismiss() {
        let app = launchIsolatedUITestApp()

        saveTip(named: "Insight Detail Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.buttons["Saved Insights"].tap()

        XCTAssertTrue(app.navigationBars["Saved Insights"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["Saved Insights This Month"].exists)
        XCTAssertTrue(app.otherElements["Saved Insights All Time"].exists)
        XCTAssertTrue(app.otherElements["Saved Insights Highlights"].exists)
        XCTAssertTrue(app.otherElements["Saved Insights Patterns"].exists)

        app.buttons["Done"].tap()

        XCTAssertTrue(app.navigationBars["Saved Tips"].waitForExistence(timeout: 2))
    }

    func test_savedSearch_shouldShowNoMatchingTips() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Findable Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].typeText("No Results Expected")

        XCTAssertTrue(app.staticTexts["No Matching Tips"].exists)
    }

    func test_savedRename_shouldUpdateDisplayedName() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Rename Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Rename Dinner")).firstMatch.press(forDuration: 1)
        app.buttons["Rename"].tap()
        app.alerts["Rename Saved Tip"].scrollViews.otherElements.textFields["Enter Name"].tap()
        app.alerts["Rename Saved Tip"].scrollViews.otherElements.textFields["Enter Name"].typeText(" Updated")
        app.alerts["Rename Saved Tip"].scrollViews.otherElements.buttons["OK"].tap()

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Rename Dinner Updated")).firstMatch.exists)
    }

    func test_savedRowAccessibilitySummary_shouldBeDiscoverable() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Accessible Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Accessible Dinner")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Per Person")).firstMatch.exists)
    }

    func test_savedCard_shouldOpenDetailSheet() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Sheet Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Sheet Dinner")).firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Saved Tip Details"].exists)
        XCTAssertTrue(app.buttons["Use Saved Tip Again"].exists)
        XCTAssertTrue(app.buttons["Rename"].exists)
        XCTAssertTrue(app.buttons["Delete"].exists)
    }

    func test_savedDetailUseAgain_shouldReturnToCalculatorWithSavedInputs() {
        let app = XCUIApplication()
        app.launch()

        enterBillAmount("25", in: app)
        app.buttons["20%"].tap()
        app.buttons["Increase People"].tap()
        app.buttons["Save Tip Calculation"].tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.textFields["Enter Name"].typeText("Reuse Dinner")
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["OK"].tap()

        let savedAlert = app.alerts["Saved"]
        if savedAlert.waitForExistence(timeout: 2) {
            savedAlert.buttons["OK"].tap()
        }

        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Reuse Dinner")).firstMatch.tap()
        app.buttons["Use Saved Tip Again"].tap()

        XCTAssertTrue(app.navigationBars["TipSavvy"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["20%"].value as? String, "Selected")
        XCTAssertEqual(app.otherElements["Number of People"].value as? String, "2")
    }

    func test_calculateRoundCopySaveAndOpenDetail_shouldCompletePrimaryFlow() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()

        enterBillAmount("25", in: app)
        app.buttons["20%"].tap()
        app.buttons["Increase People"].tap()
        app.buttons["Total Up"].tap()

        XCTAssertTrue(app.staticTexts["Rounding Explanation"].waitForExistence(timeout: 2))

        app.buttons["Copy Per Person"].tap()
        XCTAssertTrue(app.staticTexts["Copied Confirmation"].waitForExistence(timeout: 2))

        app.buttons["Save Tip Calculation"].tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.textFields["Enter Name"].typeText("E2E Dinner")
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["OK"].tap()

        let savedAlert = app.alerts["Saved"]
        if savedAlert.waitForExistence(timeout: 2) {
            savedAlert.buttons["OK"].tap()
        }

        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        let savedTip = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "E2E Dinner")).firstMatch
        XCTAssertTrue(savedTip.waitForExistence(timeout: 2))
        savedTip.tap()

        XCTAssertTrue(app.navigationBars["Saved Tip Details"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Copy Details"].exists)
        XCTAssertTrue(app.buttons["Share"].exists)
    }
    
    func test_keyboardDoneButton_shouldDimissKeyboard() {
        let app = XCUIApplication()
        app.textFields["Enter Bill Amount"].tap()
        app.toolbars["Toolbar"]/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".otherElements[\"Done\"].buttons[\"Done\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

    private func enterBillAmount(_ amount: String, in app: XCUIApplication) {
        let enterBillAmountTextField = app.textFields["Enter Bill Amount"]
        enterBillAmountTextField.tap()
        enterBillAmountTextField.typeText(amount)
        app.toolbars["Toolbar"]/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".otherElements[\"Done\"].buttons[\"Done\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

    private func saveTip(named name: String, in app: XCUIApplication) {
        app.tabBars["Tab Bar"].buttons["Calculate"].tap()
        enterBillAmount("25", in: app)
        app.buttons["Save Tip Calculation"].tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.textFields["Enter Name"].typeText(name)
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["OK"].tap()

        let savedAlert = app.alerts["Saved"]
        if savedAlert.waitForExistence(timeout: 2) {
            savedAlert.buttons["OK"].tap()
        }
    }

    private func launchIsolatedUITestApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launchArguments += ["-AppleLanguages", "(en-US)"]
        app.launchArguments += ["-AppleLocale", "\"en-US\""]
        app.launch()
        return app
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
