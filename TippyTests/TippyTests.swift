//
//  TippyTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 5/14/23.
//

import XCTest
@testable import Tippy

final class TippyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    // naming test_[what]_[expected result]
    // given, when, then
    
    // Regular Use
    func test_totalAmountWithTip_shouldBeTrue() {
        let viewModel = ContentViewModel()
        
        viewModel.billAmount = 25.00
        viewModel.tipPercentage = 15
        
        let totalWithTip = viewModel.totalAmountWithTip
        
        XCTAssertEqual(totalWithTip, 28.75)
    }
    
    func test_billAmount_shouldAcceptLargeValue() {
        let viewModel = ContentViewModel()
        
        viewModel.billAmount = 1_000_000_000_000_000
        viewModel.tipPercentage = 20
        
        let total = viewModel.totalAmountWithTip
        let expectedValue = 1_000_000_000_000_000 + (1_000_000_000_000_000 * 0.20)
        
        XCTAssertEqual(total, expectedValue)
    }
    
    // Large Bill Amount
    func test_totalPerPerson_shouldBeTrue() {
        let viewModel = ContentViewModel()
        
        viewModel.billAmount = 129.99
        viewModel.tipPercentage = 20
        viewModel.numberOfPeople = 5
        
        let totalPerPerson = viewModel.totalPerPerson
        let totalPerPersonRounded = String(format: "%.2f", totalPerPerson)
        
        XCTAssertEqual(Double(totalPerPersonRounded), 31.2)
    }
    
    // Min Tip
    func test_tipPercentage_shouldAcceptMinimum() {
        let viewModel = ContentViewModel()
        
        viewModel.tipPercentage = 0
        viewModel.billAmount = 100
        
        let total = viewModel.totalAmountWithTip
        
        XCTAssertEqual(total, 100)
    }
    
    // Max Tip
    func test_tipPercentage_shouldAcceptMaximum() {
        let viewModel = ContentViewModel()
        
        viewModel.tipPercentage = 25
        viewModel.billAmount = 100
        
        let total = viewModel.totalAmountWithTip
        
        XCTAssertEqual(total, 125)
    }
    
    // Zero Bill Amount
    func test_totalAmountWithTip_shouldBeZero() {
        let viewModel = ContentViewModel()
        
        viewModel.billAmount = 0
        viewModel.tipPercentage = 0
        
        let total = viewModel.totalAmountWithTip
        
        XCTAssertTrue(total == 0)
    }
    
    // Min People Split
    func test_numberOfPeople_shouldAcceptMin() {
        let viewModel = ContentViewModel()
        
        viewModel.numberOfPeople = 2
        viewModel.billAmount = 6
        viewModel.tipPercentage = 0
        
        let totalPerPerson = viewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 3)
    }
    
    // Max People Split
    func test_totalPerPerson_shouldBeZero() {
        let viewModel = ContentViewModel()
        
        viewModel.billAmount = 0
        viewModel.tipPercentage = 0
        viewModel.numberOfPeople = 99
        
        let totalPerPerson = viewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 0)
    }
    
    // tip amount
    func test_tipAmount_shouldBeEqual() {
        let viewModel = ContentViewModel()
        
        viewModel.billAmount = 100
        viewModel.tipPercentage = 15
        
        let tip = viewModel.tipAmount
        
        XCTAssertEqual(tip, 15)
    }
    
    func test_tipItemName_shouldBeEmptyString() {
        let viewModel = ContentViewModel()
                
        viewModel.tipItemName = ""
        
        XCTAssertEqual("", viewModel.tipItemName)
    }
    
    func test_tipItemName_shouldBeEqual() {
        let viewModel = ContentViewModel()
        
        viewModel.tipItemName = "Pizza"
        
        XCTAssertEqual("Pizza", viewModel.tipItemName)
    }
    
    func test_resetValues_shouldResetValues() {
        let viewModel = ContentViewModel()
        
        viewModel.billAmount = 15.99
        viewModel.tipPercentage = 15
        viewModel.numberOfPeople = 2
                
        viewModel.resetValues()
        
        XCTAssertNil(viewModel.billAmount)
        XCTAssertEqual(viewModel.tipAmount, 0.0)
        XCTAssertNil(viewModel.numberOfPeople)
    }
}
