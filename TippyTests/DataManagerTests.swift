//
//  DataManagerTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 10/9/23.
//

import XCTest
@testable import Tippy

final class DataManagerTests: XCTestCase {
    
    private var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager()
    }
    
    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }
    
    func test_saveTip_shouldBeTrue() {
        dataManager.saveTip(name: "Test Tip", billAmount: 100.0, tipPercentage: 0.15, numberOfPeople: 2, tipAmount: 15.0, totalAmountWithTip: 115.0, totalPerPerson: 57.5)
        
        XCTAssertEqual(dataManager.savedTips.last?.name, "Test Tip")
    }
}
