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

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
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
        
        // given
        viewModel.billAmount = 25.00
        viewModel.tipPercentage = 15
        
        // when
        let totalWithTip = viewModel.totalAmountWithTip
        
        // then
        XCTAssertEqual(totalWithTip, 28.75)
    }
    
    func test_billAmount_shouldAcceptLargeValue() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.billAmount = 1_000_000_000_000_000
        viewModel.tipPercentage = 20
        
        // when, presenting a number w/ 2 decimal places
        let total = viewModel.totalAmountWithTip
        let expectedValue = 1_000_000_000_000_000 + (1_000_000_000_000_000 * 0.20)
        
        // then
        XCTAssertEqual(total, expectedValue)
    }
    
    // Large Bill Amount
    func test_totalPerPerson_shouldBeTrue() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.billAmount = 129.99
        viewModel.tipPercentage = 20
        viewModel.numberOfPeople = 5
        
        // when, presenting a number w/ 2 decimal places
        let totalPerPerson = viewModel.totalPerPerson
        let totalPerPersonRounded = String(format: "%.2f", totalPerPerson)
        
        // then
        XCTAssertEqual(Double(totalPerPersonRounded), 31.2)
    }
    
    // Min Tip
    func test_tipPercentage_shouldAcceptMinimum() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.tipPercentage = 0
        viewModel.billAmount = 100
        
        // when
        let total = viewModel.totalAmountWithTip
        
        // then
        XCTAssertEqual(total, 100)
    }
    
    // Max Tip
    func test_tipPercentage_shouldAcceptMaximum() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.tipPercentage = 25
        viewModel.billAmount = 100
        
        // when
        let total = viewModel.totalAmountWithTip
        
        // then
        XCTAssertEqual(total, 125)
    }
    
    // Zero Bill Amount
    func test_totalAmountWithTip_shouldBeZero() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.billAmount = 0
        viewModel.tipPercentage = 0
        
        // when
        let total = viewModel.totalAmountWithTip
        
        // then
        XCTAssertTrue(total == 0)
    }
    
    // Min People Split
    func test_numberOfPeople_shouldAcceptMin() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.numberOfPeople = 2
        viewModel.billAmount = 6
        viewModel.tipPercentage = 0
        
        // when
        let totalPerPerson = viewModel.totalPerPerson
        
        // then
        XCTAssertTrue(totalPerPerson == 3)
    }
    
    // Max People Split
    func test_totalPerPerson_shouldBeZero() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.billAmount = 0
        viewModel.tipPercentage = 0
        viewModel.numberOfPeople = 99
        
        // when
        let totalPerPerson = viewModel.totalPerPerson
        
        // then
        XCTAssertTrue(totalPerPerson == 0)
    }
    
    // tip amount
    func test_tipAmount_shouldBeEqual() {
        let viewModel = ContentViewModel()
        
        // given
        viewModel.billAmount = 100
        viewModel.tipPercentage = 15
        
        // when
        let tip = viewModel.tipAmount
        
        // then
        XCTAssertEqual(tip, 15)
    }
}
