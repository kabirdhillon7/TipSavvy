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
        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Save Tip Calculation"]/*[[".cells.buttons[\"Save Tip Calculation\"]",".buttons[\"Save Tip Calculation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["Cancel"].tap()
    }
    
    func test_enterbillAmountTextField_shouldAcceptInput() {
        let app = XCUIApplication()
        app.launch()
        
        let enterBillAmountTextField = app.collectionViews/*@START_MENU_TOKEN@*/.textFields["Enter Bill Amount"]/*[[".cells.textFields[\"Enter Bill Amount\"]",".textFields[\"Enter Bill Amount\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        enterBillAmountTextField.tap()
        
        app/*@START_MENU_TOKEN@*/.keys["2"]/*[[".keyboards.keys[\"2\"]",".keys[\"2\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["4"]/*[[".keyboards.keys[\"4\"]",".keys[\"4\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["Delete"]/*[[".keyboards.keys[\"Delete\"]",".keys[\"Delete\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["5"]/*[[".keyboards.keys[\"5\"]",".keys[\"5\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func test_slider_shouldTapAndSwipeRight() {
        let app = XCUIApplication()
        app.launch()
        
        let tipPercentageSelectionSlider = XCUIApplication().collectionViews/*@START_MENU_TOKEN@*/.sliders["Tip Percentage Selection"]/*[[".cells.sliders[\"Tip Percentage Selection\"]",".sliders[\"Tip Percentage Selection\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        tipPercentageSelectionSlider.tap()
        tipPercentageSelectionSlider.swipeRight()
        tipPercentageSelectionSlider.swipeRight()
    }
    
    func test_stepper_shouldAdjustNumberOfPeople() {
        let app = XCUIApplication()
        app.launch()
        
        let peopleStepper = app.collectionViews.steppers["Number of People"]
        peopleStepper.buttons["Increment"].tap()
        peopleStepper.buttons["Decrement"].tap()
    }

    func test_tipPreset_shouldSelectTwentyPercent() {
        let app = XCUIApplication()
        app.launch()

        app.collectionViews.buttons["20%"].tap()
        XCTAssertEqual(app.collectionViews.buttons["20%"].value as? String, "Selected")
    }

    func test_calculatorAccessibilityElements_shouldBeDiscoverable() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
        app.launchArguments += ["-UIAccessibilityReduceMotionEnabled", "YES"]
        app.launch()

        XCTAssertTrue(app.collectionViews.textFields["Enter Bill Amount"].exists)
        XCTAssertTrue(app.collectionViews.steppers["Number of People"].exists)
        XCTAssertTrue(app.collectionViews.buttons["15%"].exists)
        XCTAssertTrue(app.collectionViews.sliders["Tip Percentage Selection"].exists)
        XCTAssertTrue(app.collectionViews.buttons["Save Tip Calculation"].exists)
        XCTAssertTrue(app.collectionViews.buttons["Reset"].exists)
        XCTAssertTrue(app.collectionViews.otherElements["Bill Totals Summary"].exists)
    }

    func test_tipPreset_shouldPersistAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()

        app.collectionViews.buttons["20%"].tap()
        app.terminate()
        app.launch()

        XCTAssertEqual(app.collectionViews.buttons["20%"].value as? String, "Selected")
    }

    func test_stepper_shouldPersistPeopleCountAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()

        let peopleStepper = app.collectionViews.steppers["Number of People"]
        peopleStepper.buttons["Increment"].tap()
        app.terminate()
        app.launch()

        XCTAssertEqual(app.collectionViews.steppers["Number of People"].value as? String, "2")
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
        
        let collectionViewsQuery = app.collectionViews
        let resetButton = collectionViewsQuery/*@START_MENU_TOKEN@*/.buttons["Reset"]/*[[".cells.buttons[\"Reset\"]",".buttons[\"Reset\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        resetButton.tap()
    }
    
    func test_saveTipCalculationButton_shouldBeDisabledForInvalidCalculation() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertFalse(app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Save Tip Calculation"]/*[[".cells.buttons[\"Save Tip Calculation\"]",".buttons[\"Save Tip Calculation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.isEnabled)
    }
    
    func test_saveTipCalculationButton_shouldSave() {
        let app = XCUIApplication()
        app.launch()

        enterBillAmount("25", in: app)

        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Save Tip Calculation"]/*[[".cells.buttons[\"Save Tip Calculation\"]",".buttons[\"Save Tip Calculation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.textFields["Enter Name"].typeText("Lunch")
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["OK"].tap()
    }
    
    func test_saveTipCalculationButton_shouldCancel() {
        let app = XCUIApplication()
        app.launch()

        enterBillAmount("25", in: app)
        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Save Tip Calculation"]/*[[".cells.buttons[\"Save Tip Calculation\"]",".buttons[\"Save Tip Calculation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["Cancel"].tap()
    }

    func test_savedSearch_shouldFilterByName() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Search Lunch", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].tap()
        app.navigationBars["Saved Tips"].searchFields["Search Saved Tips"].typeText("Search Lunch")

        XCTAssertTrue(app.collectionViews.staticTexts["Search Lunch"].exists)
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
        app.collectionViews.staticTexts["Rename Dinner"].press(forDuration: 1)
        app.buttons["Rename"].tap()
        app.alerts["Rename Saved Tip"].scrollViews.otherElements.textFields["Enter Name"].tap()
        app.alerts["Rename Saved Tip"].scrollViews.otherElements.textFields["Enter Name"].typeText(" Updated")
        app.alerts["Rename Saved Tip"].scrollViews.otherElements.buttons["OK"].tap()

        XCTAssertTrue(app.collectionViews.staticTexts["Rename Dinner Updated"].exists)
    }

    func test_savedRowAccessibilitySummary_shouldBeDiscoverable() {
        let app = XCUIApplication()
        app.launch()

        saveTip(named: "Accessible Dinner", in: app)
        app.tabBars["Tab Bar"].buttons["Saved"].tap()

        XCTAssertTrue(app.collectionViews.staticTexts["Accessible Dinner"].exists)
        XCTAssertTrue(app.collectionViews.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Per Person")).element.exists)
    }
    
    func test_keyboardDoneButton_shouldDimissKeyboard() {
        let app = XCUIApplication()
        app.collectionViews/*@START_MENU_TOKEN@*/.textFields["Enter Bill Amount"]/*[[".cells.textFields[\"Enter Bill Amount\"]",".textFields[\"Enter Bill Amount\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.toolbars["Toolbar"]/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".otherElements[\"Done\"].buttons[\"Done\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

    private func enterBillAmount(_ amount: String, in app: XCUIApplication) {
        let enterBillAmountTextField = app.collectionViews/*@START_MENU_TOKEN@*/.textFields["Enter Bill Amount"]/*[[".cells.textFields[\"Enter Bill Amount\"]",".textFields[\"Enter Bill Amount\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        enterBillAmountTextField.tap()
        enterBillAmountTextField.typeText(amount)
        app.toolbars["Toolbar"]/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".otherElements[\"Done\"].buttons[\"Done\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

    private func saveTip(named name: String, in app: XCUIApplication) {
        app.tabBars["Tab Bar"].buttons["Calculate"].tap()
        enterBillAmount("25", in: app)
        app.collectionViews.buttons["Save Tip Calculation"].tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.textFields["Enter Name"].typeText(name)
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["OK"].tap()
    }
}
