//
//  CurrencyInputTests.swift
//  TipSavvyTests
//

import XCTest
@testable import TipSavvy

final class CurrencyInputTests: XCTestCase {
    private let us = Locale(identifier: "en_US")
    private let germany = Locale(identifier: "de_DE")

    func test_sanitize_keepsDigitsAndOneSeparator() {
        XCTAssertEqual(CurrencyInput.sanitize("$1,2a4.5.6", locale: us), "124.56")
        XCTAssertEqual(CurrencyInput.sanitize("24.999", locale: us), "24.99")
        XCTAssertEqual(CurrencyInput.sanitize("24,50", locale: germany), "24,50")
    }

    func test_parse_readsPartialInputWithoutLosingDigits() {
        XCTAssertEqual(CurrencyInput.parse("2", locale: us), 2)
        XCTAssertEqual(CurrencyInput.parse("24", locale: us), 24)
        XCTAssertEqual(CurrencyInput.parse("24.", locale: us), 24)
        XCTAssertEqual(CurrencyInput.parse("24.5", locale: us), 24.5)
        XCTAssertEqual(CurrencyInput.parse("24,5", locale: germany), 24.5)
        XCTAssertNil(CurrencyInput.parse("", locale: us))
        XCTAssertNil(CurrencyInput.parse(".", locale: us))
    }

    func test_text_isPlainWhileEditingAndPaddedAtRest() {
        XCTAssertEqual(CurrencyInput.text(for: 24, padded: false, locale: us), "24")
        XCTAssertEqual(CurrencyInput.text(for: 24.5, padded: false, locale: us), "24.5")
        XCTAssertEqual(CurrencyInput.text(for: 24, padded: true, locale: us), "24.00")
        XCTAssertEqual(CurrencyInput.text(for: 1234.5, padded: true, locale: us), "1234.50")
        XCTAssertEqual(CurrencyInput.text(for: nil, padded: true, locale: us), "")
    }

    func test_symbolPlacementFollowsLocale() {
        XCTAssertTrue(CurrencyInput.symbolLeads(currencyCode: "USD", locale: us))
        XCTAssertFalse(CurrencyInput.symbolLeads(currencyCode: "EUR", locale: germany))
        XCTAssertEqual(CurrencyInput.symbol(currencyCode: "USD", locale: us), "$")
    }
}
