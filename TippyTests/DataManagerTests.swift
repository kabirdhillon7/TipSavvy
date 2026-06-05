//
//  DataManagerTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 10/9/23.
//

import XCTest
@testable import Tippy

@MainActor
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
        let result = dataManager.saveTip(name: "Test Tip", billAmount: 100.0, tipPercentage: 15, numberOfPeople: 2, tipAmount: 15.0, totalAmountWithTip: 115.0, totalPerPerson: 57.5)
        
        XCTAssertNotNil(try? result.get())
        XCTAssertEqual(dataManager.savedTips.last?.name, "Test Tip")
    }

    func test_saveTip_withBlankName_shouldReturnEmptyNameError() {
        let result = dataManager.saveTip(name: "   ", billAmount: 100.0, tipPercentage: 15, numberOfPeople: 2, tipAmount: 15.0, totalAmountWithTip: 115.0, totalPerPerson: 57.5)

        XCTAssertEqual(result.failureValue, .emptyName)
        XCTAssertEqual(dataManager.lastError, .emptyName)
        XCTAssertTrue(dataManager.savedTips.isEmpty)
    }

    func test_saveTip_shouldSortNewestFirst() {
        let olderDate = Date(timeIntervalSince1970: 1)
        let newerDate = Date(timeIntervalSince1970: 2)

        dataManager.saveTip(name: "Older Tip", billAmount: 50.0, tipPercentage: 15, numberOfPeople: 1, tipAmount: 7.5, totalAmountWithTip: 57.5, totalPerPerson: 57.5, date: olderDate)
        dataManager.saveTip(name: "Newer Tip", billAmount: 100.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 60.0, date: newerDate)

        XCTAssertEqual(dataManager.savedTips.first?.name, "Newer Tip")
        XCTAssertEqual(dataManager.savedTips.last?.name, "Older Tip")
    }

    func test_saveTip_withNoteAndTaxMetadata_shouldPersistOptionalFields() {
        dataManager.saveTip(name: "Tax Dinner",
                            note: "Window table",
                            billAmount: 100,
                            tipPercentage: 20,
                            numberOfPeople: 2,
                            tipAmount: 20,
                            totalAmountWithTip: 128,
                            totalPerPerson: 64,
                            subtotalAmount: 100,
                            taxAmount: 8,
                            tipsOnTax: false)

        let tip = dataManager.savedTips.first

        XCTAssertEqual(tip?.note, "Window table")
        XCTAssertEqual(tip?.subtotalAmount?.doubleValue, 100)
        XCTAssertEqual(tip?.taxAmount?.doubleValue, 8)
        XCTAssertEqual(tip?.tipsOnTax?.boolValue, false)
        XCTAssertEqual(tip?.hasTaxBreakdown, true)
    }

    func test_saveTip_withoutOptionalMetadata_shouldBehaveLikeLegacySavedTip() {
        dataManager.saveTip(name: "Simple Dinner", billAmount: 80, tipPercentage: 20, numberOfPeople: 2, tipAmount: 16, totalAmountWithTip: 96, totalPerPerson: 48)

        let tip = dataManager.savedTips.first

        XCTAssertNil(tip?.note)
        XCTAssertNil(tip?.subtotalAmount)
        XCTAssertNil(tip?.taxAmount)
        XCTAssertNil(tip?.tipsOnTax)
        XCTAssertEqual(tip?.hasTaxBreakdown, false)
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

    func test_savedTipAccessibilitySummary_shouldIncludeNameDateTotalAndPerPerson() {
        let savedDate = Date(timeIntervalSince1970: 1_704_067_200)
        let dateFormat = Date.FormatStyle.dateTime.month().day().year()

        dataManager.saveTip(name: "Accessibility Dinner", billAmount: 100.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 60.0, date: savedDate)

        guard let tip = dataManager.savedTips.first else {
            XCTFail("Expected saved tip")
            return
        }

        let summary = tip.accessibilitySummary(currencyCode: "USD", dateFormat: dateFormat)

        XCTAssertTrue(summary.contains("Accessibility Dinner"))
        XCTAssertTrue(summary.contains(savedDate.formatted(dateFormat)))
        XCTAssertTrue(summary.contains("Total With Tip"))
        XCTAssertTrue(summary.contains("120.00"))
        XCTAssertTrue(summary.contains("Per Person"))
        XCTAssertTrue(summary.contains("60.00"))
    }

    func test_savedTipShareText_shouldIncludeCalculationDetails() {
        dataManager.saveTip(name: "Share Dinner", billAmount: 80.0, tipPercentage: 20, numberOfPeople: 2, tipAmount: 16.0, totalAmountWithTip: 96.0, totalPerPerson: 48.0, date: Date(timeIntervalSince1970: 1_704_067_200))

        guard let tip = dataManager.savedTips.first else {
            XCTFail("Expected saved tip")
            return
        }

        let shareText = tip.shareText(currencyCode: "USD")

        XCTAssertTrue(shareText.contains("Share Dinner"))
        XCTAssertTrue(shareText.contains("Bill Amount"))
        XCTAssertTrue(shareText.contains("80.00"))
        XCTAssertTrue(shareText.contains("20%"))
        XCTAssertTrue(shareText.contains("Per Person"))
    }

    func test_savedTipShareText_withNoteAndTax_shouldIncludeOptionalDetails() {
        dataManager.saveTip(name: "Tax Share",
                            note: "Birthday",
                            billAmount: 100,
                            tipPercentage: 20,
                            numberOfPeople: 2,
                            tipAmount: 20,
                            totalAmountWithTip: 128,
                            totalPerPerson: 64,
                            subtotalAmount: 100,
                            taxAmount: 8,
                            tipsOnTax: false)

        guard let tip = dataManager.savedTips.first else {
            XCTFail("Expected saved tip")
            return
        }

        let shareText = tip.shareText(currencyCode: "USD")

        XCTAssertTrue(shareText.contains("Subtotal"))
        XCTAssertTrue(shareText.contains("Tax"))
        XCTAssertTrue(shareText.contains("Tip Basis"))
        XCTAssertTrue(shareText.contains("Birthday"))
    }
}

private extension Result {
    var failureValue: Failure? {
        guard case let .failure(error) = self else {
            return nil
        }

        return error
    }
}
