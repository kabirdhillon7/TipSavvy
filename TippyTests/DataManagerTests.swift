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
        dataManager = DataManager(inMemory: true)
    }
    
    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }
    
    func test_saveTip_shouldBeTrue() {
        dataManager.saveTip(name: "Test Tip", billAmount: 100.0, tipPercentage: 0.15, numberOfPeople: 2, tipAmount: 15.0, totalAmountWithTip: 115.0, totalPerPerson: 57.5)
        
        XCTAssertEqual(dataManager.savedTips.last?.name, "Test Tip")
    }

    func test_saveTip_shouldSortNewestFirst() {
        let olderDate = Date(timeIntervalSince1970: 1)
        let newerDate = Date(timeIntervalSince1970: 2)

        dataManager.saveTip(name: "Older Tip", billAmount: 50.0, tipPercentage: 15, numberOfPeople: 1, tipAmount: 7.5, totalAmountWithTip: 57.5, totalPerPerson: 57.5, date: olderDate)
        dataManager.saveTip(name: "Newer Tip", billAmount: 100.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 60.0, date: newerDate)

        XCTAssertEqual(dataManager.savedTips.first?.name, "Newer Tip")
        XCTAssertEqual(dataManager.savedTips.last?.name, "Older Tip")
    }

    func test_deleteTips_shouldRemoveTip() {
        dataManager.saveTip(name: "Tip to Delete", billAmount: 100.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 60.0)

        dataManager.deleteTips(at: IndexSet(integer: 0))

        XCTAssertTrue(dataManager.savedTips.isEmpty)
    }

    func test_renameTip_shouldUpdateExpectedTip() {
        dataManager.saveTip(name: "Dinner", billAmount: 100.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 60.0)

        guard let tip = dataManager.savedTips.first else {
            XCTFail("Expected saved tip")
            return
        }

        dataManager.renameTip(tip, to: "Team Dinner")

        XCTAssertEqual(dataManager.savedTips.first?.name, "Team Dinner")
    }

    func test_renameTip_withBlankName_shouldKeepExistingName() {
        dataManager.saveTip(name: "Dinner", billAmount: 100.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 60.0)

        guard let tip = dataManager.savedTips.first else {
            XCTFail("Expected saved tip")
            return
        }

        dataManager.renameTip(tip, to: "   ")

        XCTAssertEqual(dataManager.savedTips.first?.name, "Dinner")
    }

    func test_renameTip_shouldPreserveNewestFirstOrdering() {
        let olderDate = Date(timeIntervalSince1970: 1)
        let newerDate = Date(timeIntervalSince1970: 2)

        dataManager.saveTip(name: "Older Tip", billAmount: 50.0, tipPercentage: 15, numberOfPeople: 1, tipAmount: 7.5, totalAmountWithTip: 57.5, totalPerPerson: 57.5, date: olderDate)
        dataManager.saveTip(name: "Newer Tip", billAmount: 100.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 60.0, date: newerDate)

        guard let olderTip = dataManager.savedTips.last else {
            XCTFail("Expected older tip")
            return
        }

        dataManager.renameTip(olderTip, to: "Renamed Older Tip")

        XCTAssertEqual(dataManager.savedTips.first?.name, "Newer Tip")
        XCTAssertEqual(dataManager.savedTips.last?.name, "Renamed Older Tip")
    }
}
