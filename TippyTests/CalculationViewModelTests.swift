//
//  CalculationViewModelTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 10/9/23.
//

import XCTest
@testable import Tippy

final class CalculationViewModelTests: XCTestCase {
    
    private var calculationViewModel: CalculationViewModel!
    
    override func setUp() {
        super.setUp()
        calculationViewModel = CalculationViewModel()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // naming test_[what]_[expected result]
    // given, when, then
    
    // Regular Use
    func test_totalAmountWithTip_shouldBeTrue() {
        calculationViewModel.billAmount = 25.00
        calculationViewModel.tipPercentage = 15
        
        let totalWithTip = calculationViewModel.totalAmountWithTip
        
        XCTAssertEqual(totalWithTip, 28.75)
    }
    
    func test_billAmount_shouldAcceptLargeValue() {
        calculationViewModel.billAmount = 1_000_000_000_000_000
        calculationViewModel.tipPercentage = 20
        
        let total = calculationViewModel.totalAmountWithTip
        let expectedValue = 1_000_000_000_000_000 + (1_000_000_000_000_000 * 0.20)
        
        XCTAssertEqual(total, expectedValue)
    }
    
    // Large Bill Amount
    func test_totalPerPerson_shouldBeTrue() {
        calculationViewModel.billAmount = 129.99
        calculationViewModel.tipPercentage = 20
        calculationViewModel.numberOfPeople = 5
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        let totalPerPersonRounded = String(format: "%.2f", totalPerPerson)
        
        XCTAssertEqual(Double(totalPerPersonRounded), 31.2)
    }
    
    // Max People Split
    func test_totalPerPerson_shouldBeZero() {
        calculationViewModel.billAmount = 0
        calculationViewModel.tipPercentage = 0
        calculationViewModel.numberOfPeople = 99
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 0)
    }
    
    func testTotalPerPerson_withInvalidTotal() {
        calculationViewModel.billAmount = 100
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 0
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertEqual(totalPerPerson, 0)
    }
    
    func testTotalPerPerson_withNaNTotal() {
        calculationViewModel.billAmount = Double.nan
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 2
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertEqual(totalPerPerson, 0)
    }
    
    func testTotalPerPerson_withInfiniteTotal() {
        calculationViewModel.billAmount = Double.infinity
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 2
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertEqual(totalPerPerson, 0)
    }
    
    // Check for 0 bill total, but multiple people
    func test_totalPerPerson_shouldReturnTrueForZeroBillAmount() {
        calculationViewModel.billAmount = 0
        calculationViewModel.numberOfPeople = 10
        calculationViewModel.tipPercentage = 10
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 0)
    }

    // Min Tip
    func test_tipPercentage_shouldAcceptMinimum() {
        calculationViewModel.tipPercentage = 0
        calculationViewModel.billAmount = 100
        
        let total = calculationViewModel.totalAmountWithTip
        
        XCTAssertEqual(total, 100)
    }
    
    // Max Tip
    func test_tipPercentage_shouldAcceptMaximum() {
        calculationViewModel.tipPercentage = 25
        calculationViewModel.billAmount = 100
        
        let total = calculationViewModel.totalAmountWithTip
        
        XCTAssertEqual(total, 125)
    }
    
    // Zero Bill Amount
    func test_totalAmountWithTip_shouldBeZero() {
        calculationViewModel.billAmount = 0
        calculationViewModel.tipPercentage = 0
        
        let total = calculationViewModel.totalAmountWithTip
        
        XCTAssertTrue(total == 0)
    }
    
    // Min People Split
    func test_numberOfPeople_shouldAcceptMin() {
        calculationViewModel.numberOfPeople = 2
        calculationViewModel.billAmount = 6
        calculationViewModel.tipPercentage = 0
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 3)
    }
    
    // tip amount
    func test_tipAmount_shouldBeEqual() {
        calculationViewModel.billAmount = 100
        calculationViewModel.tipPercentage = 15
        
        let tip = calculationViewModel.tipAmount
        
        XCTAssertEqual(tip, 15)
    }
    
    func test_tipAmount_shouldBeEqualForNilBillAmount() {
        calculationViewModel.billAmount = nil
        calculationViewModel.tipPercentage = 15
        
        let tipAmount = calculationViewModel.tipAmount
        
        XCTAssertEqual(tipAmount, 0)
    }
    
    func test_tipItemName_shouldBeEmptyString() {
        calculationViewModel.tipItemName = ""
        
        XCTAssertEqual("", calculationViewModel.tipItemName)
    }
    
    func test_tipItemName_shouldBeEqual() {
        calculationViewModel.tipItemName = "Pizza"
        
        XCTAssertEqual("Pizza", calculationViewModel.tipItemName)
    }
    
    func test_resetValues_shouldResetValues() {
        calculationViewModel.billAmount = 15.99
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 2
        calculationViewModel.tipItemName = "Sandwiches"
                
        calculationViewModel.resetValues()
        
        XCTAssertNil(calculationViewModel.billAmount)
        XCTAssertEqual(calculationViewModel.tipPercentage, 0.0)
        XCTAssertNil(calculationViewModel.numberOfPeople)
        XCTAssertEqual(calculationViewModel.tipItemName, "")
    }
    
    func test_resetValues_shouldReturnTrue() {
        calculationViewModel.resetValues()
        
        XCTAssertTrue(calculationViewModel.billAmount == nil)
        XCTAssertTrue(calculationViewModel.tipPercentage == 0)
        XCTAssertTrue(calculationViewModel.numberOfPeople == nil)
        XCTAssertTrue(calculationViewModel.tipItemName == "")
    }

}
