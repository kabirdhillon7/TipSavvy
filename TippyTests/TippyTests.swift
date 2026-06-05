//
//  TippyTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 5/14/23.
//

import XCTest
import FirebaseCore

@testable import Tippy

final class TippyTests: XCTestCase {

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func test_calculateTipIntentSummary_shouldIncludeTipTotalAndPerPersonAmounts() {
        let summary = CalculateTipIntent.summary(billAmount: 100,
                                                 tipPercentage: 20,
                                                 numberOfPeople: 2,
                                                 currencyCode: "USD")

        XCTAssertTrue(summary.contains("20.00"))
        XCTAssertTrue(summary.contains("120.00"))
        XCTAssertTrue(summary.contains("60.00"))
    }

    func test_calculateTipIntentSummary_shouldClampInvalidInputs() {
        let summary = CalculateTipIntent.summary(billAmount: .infinity,
                                                 tipPercentage: 200,
                                                 numberOfPeople: 0,
                                                 currencyCode: "USD")

        XCTAssertTrue(summary.contains("0.00"))
    }
}
