//
//  SavedTipFilterTests.swift
//  TippyTests
//
//  Created by OpenAI Codex on 5/8/26.
//

import XCTest
@testable import Tippy

@MainActor
final class SavedTipFilterTests: XCTestCase {
    private var dataManager: DataManager!

    override func setUp() {
        super.setUp()
        dataManager = DataManager(inMemory: true)
    }

    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }

    func test_filterMode_all_shouldIncludeEverySavedTip() throws {
        let tip = try makeTip(name: "Lunch", tipPercentage: 15, date: Date())

        XCTAssertTrue(SavedTipFilterMode.all.includes(tip))
    }

    func test_filterMode_recent_shouldIncludeOnlyTipsFromTheLastThirtyDays() throws {
        let recentTip = try makeTip(name: "Recent", tipPercentage: 18, date: Date().addingTimeInterval(-5 * 86_400))
        let oldTip = try makeTip(name: "Old", tipPercentage: 18, date: Date().addingTimeInterval(-45 * 86_400))

        XCTAssertTrue(SavedTipFilterMode.recent.includes(recentTip))
        XCTAssertFalse(SavedTipFilterMode.recent.includes(oldTip))
    }

    func test_filterMode_highTip_shouldIncludeTwentyPercentOrHigher() throws {
        let highTip = try makeTip(name: "Dinner", tipPercentage: 20, date: Date())
        let standardTip = try makeTip(name: "Coffee", tipPercentage: 18, date: Date())

        XCTAssertTrue(SavedTipFilterMode.highTip.includes(highTip))
        XCTAssertFalse(SavedTipFilterMode.highTip.includes(standardTip))
    }

    func test_sortMode_total_shouldSortDescendingByTotal() throws {
        let lowerTotal = try makeTip(name: "Coffee", total: 8)
        let higherTotal = try makeTip(name: "Dinner", total: 140)

        let sortedTips = SavedTipSortMode.total.sort([lowerTotal, higherTotal])

        XCTAssertEqual(sortedTips.first?.name, "Dinner")
        XCTAssertEqual(sortedTips.last?.name, "Coffee")
    }

    func test_savedTipListPreferenceKeys_shouldRemainStableForAppStorage() {
        XCTAssertEqual(SavedTipListPreferenceKey.sortMode, "savedTipSortMode")
        XCTAssertEqual(SavedTipListPreferenceKey.filterMode, "savedTipFilterMode")
    }

    private func makeTip(name: String,
                         tipPercentage: Double = 18,
                         total: Double = 42,
                         date: Date = Date()) throws -> SavedTip {
        let result = dataManager.saveTip(name: name,
                                         billAmount: total,
                                         tipPercentage: tipPercentage,
                                         numberOfPeople: 1,
                                         tipAmount: total * tipPercentage / 100,
                                         totalAmountWithTip: total,
                                         totalPerPerson: total,
                                         date: date)

        guard case .success(let tip) = result else {
            throw XCTSkip("Could not create saved tip fixture.")
        }

        return tip
    }
}
