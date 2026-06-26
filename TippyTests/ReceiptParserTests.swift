//
//  ReceiptParserTests.swift
//  TippyTests
//

import XCTest
@testable import Tippy

final class ReceiptParserTests: XCTestCase {

    func test_subtotalAndTotal_returnsTotalNotSubtotal() {
        let lines = [
            "Cafe Luna",
            "Subtotal      $40.00",
            "Tax            $3.20",
            "Total         $43.20",
            "Visa ************1234"
        ]

        XCTAssertEqual(ReceiptParser.extractBillAmount(fromLines: lines), 43.20)
    }

    func test_grandTotal_outranksPlainTotalLine() {
        let lines = [
            "Total items        3",
            "Total          $50.00",
            "Tax            $4.00",
            "Grand Total    $54.00",
            "Cash"
        ]

        XCTAssertEqual(ReceiptParser.extractBillAmount(fromLines: lines), 54.00)
    }

    func test_nonReceiptText_returnsNil() {
        // Lines of source code — numbers everywhere, but no receipt signal.
        let lines = [
            "let requiredStableCount = 2",
            "private let sanityCeiling: Double = 100000",
            "for index in 0..<42 {",
            "    matrix[index] = 3.14159",
            "}",
            "return value * 1.5"
        ]

        XCTAssertNil(ReceiptParser.extractBillAmount(fromLines: lines))
    }

    func test_noExplicitTotal_fallsBackToLargestPriceFormattedValue() {
        // Receipt-like (tax, card, item prices) but the word "total" never appears clearly.
        let lines = [
            "Burger        $12.50",
            "Fries          $4.25",
            "Soda           $2.75",
            "Tax            $1.60",
            "Card payment  $21.10"
        ]

        XCTAssertEqual(ReceiptParser.extractBillAmount(fromLines: lines), 21.10)
    }

    func test_fallbackIgnoresBareIntegers() {
        // No keyword-anchored total → Pass 2. The largest *number* is a phone/order id with no
        // price format, so it must be ignored in favor of the largest 2-decimal price.
        let lines = [
            "Order 88231",
            "Item           $9.50",
            "Tax            $0.76",
            "Cash paid     $10.26",
            "Tel 5551234567"
        ]

        XCTAssertEqual(ReceiptParser.extractBillAmount(fromLines: lines), 10.26)
    }

    func test_valueAboveSanityCeiling_isIgnored() {
        // No keyword-anchored total; fallback must skip the absurd value and pick the real price.
        let lines = [
            "Receipt",
            "Account 999999.99",
            "Item           $18.00",
            "Tax            $1.44",
            "Cash           $19.44"
        ]

        XCTAssertEqual(ReceiptParser.extractBillAmount(fromLines: lines), 19.44)
    }

    func test_emptyInput_returnsNil() {
        XCTAssertNil(ReceiptParser.extractBillAmount(fromLines: []))
    }
}
