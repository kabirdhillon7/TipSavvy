//
//  TipServiceContextTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 5/12/26.
//

import XCTest
@testable import Tippy

final class TipServiceContextTests: XCTestCase {

    func test_suggestedPresets_shouldMatchExpectedServiceRanges() {
        let expectedPresets: [TipServiceContext: [Double]] = [
            .restaurant: [15, 18, 20, 25],
            .bar: [15, 18, 20],
            .delivery: [15, 18, 20],
            .takeout: [0, 10, 15],
            .coffee: [10, 15, 20],
            .salon: [15, 20, 25],
            .barber: [15, 18, 20],
            .spa: [15, 18, 20],
            .nailSalon: [15, 18, 20],
            .petGroomer: [15, 18, 20],
            .rideshare: [10, 15, 18],
            .foodTruck: [10, 15, 18],
            .tourGuide: [15, 18, 20],
            .movers: [5, 10, 15],
            .custom: [15, 18, 20, 25]
        ]

        for context in TipServiceContext.allCases {
            XCTAssertEqual(context.suggestedPresets, expectedPresets[context])
        }
    }

    func test_suggestedPresets_shouldStayInsideSupportedTipRange() {
        for context in TipServiceContext.allCases {
            for preset in context.suggestedPresets {
                XCTAssertTrue((0...30).contains(preset), "\(context.rawValue) contains unsupported preset \(preset)")
            }
        }
    }

    func test_contextLabelsAndHelperText_shouldNotBeEmpty() {
        for context in TipServiceContext.allCases {
            XCTAssertFalse(context.label.isEmpty)
            XCTAssertFalse(context.helperText.isEmpty)
        }
    }
}
