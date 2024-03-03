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
    
    func test_picker_shouldSelectInput() {
        let app = XCUIApplication()
        app.launch()
        
        app.collectionViews/*@START_MENU_TOKEN@*/.textFields["Number of People"]/*[[".cells.textFields[\"Number of People\"]",".textFields[\"Number of People\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["5"]/*[[".keyboards.keys[\"5\"]",".keys[\"5\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
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
    
    func test_saveTipCalculationButton_shouldTap() {
        let app = XCUIApplication()
        app.launch()
        
        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Save Tip Calculation"]/*[[".cells.buttons[\"Save Tip Calculation\"]",".buttons[\"Save Tip Calculation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func test_saveTipCalculationButton_shouldSave() {
        let app = XCUIApplication()
        app.launch()
        
        
        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Save Tip Calculation"]/*[[".cells.buttons[\"Save Tip Calculation\"]",".buttons[\"Save Tip Calculation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["OK"].tap()
        
        
    }
    
    func test_saveTipCalculationButton_shouldCancel() {
        let app = XCUIApplication()
        app.launch()
        
        app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Save Tip Calculation"]/*[[".cells.buttons[\"Save Tip Calculation\"]",".buttons[\"Save Tip Calculation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts["Save Tip Calculation"].scrollViews.otherElements.buttons["Cancel"].tap()
        
    }
    
    func test_keyboardDoneButton_shouldDimissKeyboard() {
        let app = XCUIApplication()
        app.collectionViews/*@START_MENU_TOKEN@*/.textFields["Enter Bill Amount"]/*[[".cells.textFields[\"Enter Bill Amount\"]",".textFields[\"Enter Bill Amount\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.toolbars["Toolbar"]/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".otherElements[\"Done\"].buttons[\"Done\"]",".buttons[\"Done\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
}
