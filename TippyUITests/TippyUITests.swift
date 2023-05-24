//
//  TippyUITests.swift
//  TippyUITests
//
//  Created by Kabir Dhillon on 5/14/23.
//

import XCTest

final class TippyUITests: XCTestCase {

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
    
    func test_billAmountTextField_shouldAcceptInput() {
        let app = XCUIApplication()
        app.launch()
        
        let amountTextField = app.collectionViews/*@START_MENU_TOKEN@*/.textFields["Amount"]/*[[".cells.textFields[\"Amount\"]",".textFields[\"Amount\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        
        amountTextField.tap()
        amountTextField.tap()
        amountTextField.tap()
        
        let deleteKey = app/*@START_MENU_TOKEN@*/.keys["Delete"]/*[[".keyboards.keys[\"Delete\"]",".keys[\"Delete\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        app/*@START_MENU_TOKEN@*/.keys["2"]/*[[".keyboards.keys[\"2\"]",".keys[\"2\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.keys["5"]/*[[".keyboards.keys[\"5\"]",".keys[\"5\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        XCTAssertEqual(amountTextField.value as? String, "25")
    }
    
    func test_slider_shouldTapAndSwipeRight() {
        let app = XCUIApplication()
        app.launch()
        
        
        let tipPercentageSlider = XCUIApplication().collectionViews/*@START_MENU_TOKEN@*/.sliders["Tip Percentage"]/*[[".cells.sliders[\"Tip Percentage\"]",".sliders[\"Tip Percentage\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        tipPercentageSlider.swipeLeft()
        tipPercentageSlider.tap()
    }
    
    func test_picker_shouldSelectInput() {
        let app = XCUIApplication()
        app.launch()
        
        XCUIApplication().collectionViews/*@START_MENU_TOKEN@*/.staticTexts["0 people"]/*[[".cells",".buttons[\"Number of People, Number of People\"].staticTexts[\"0 people\"]",".staticTexts[\"0 people\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
}
