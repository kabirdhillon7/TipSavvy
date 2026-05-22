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

    func test_savedTipInsights_shouldSummarizeCurrentMonthTips() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 22).date!
        let currentMonthDate = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 12).date!
        let oldDate = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 4, day: 30).date!

        _ = try makeTip(name: "May Dinner", tipPercentage: 20, total: 120, tipAmount: 20, people: 2, date: currentMonthDate)
        _ = try makeTip(name: "April Dinner", tipPercentage: 10, total: 55, tipAmount: 5, people: 4, date: oldDate)

        let insights = SavedTipInsights(tips: dataManager.savedTips, now: now, calendar: calendar)

        XCTAssertEqual(insights.currentMonthTotalWithTip, 120)
        XCTAssertEqual(insights.currentMonthTipTotal, 20)
        XCTAssertEqual(insights.currentMonthSavedTipCount, 1)
        XCTAssertEqual(insights.allTimeSavedTipCount, 2)
        XCTAssertEqual(insights.allTimeTotalWithTip, 175)
        XCTAssertEqual(insights.allTimeTipTotal, 25)
        XCTAssertEqual(insights.averageBillAmount, 87.5)
        XCTAssertEqual(insights.averageTipPercentage, 15)
        XCTAssertEqual(insights.mostCommonSplitCount, 2)
        XCTAssertEqual(insights.mostCommonTipPercentage, 10)
        XCTAssertEqual(insights.largestSavedBill, 120)
        XCTAssertEqual(insights.largestSavedBillName, "May Dinner")
        XCTAssertEqual(insights.highestTipPercentage, 20)
        XCTAssertEqual(insights.highestTipName, "May Dinner")
        XCTAssertEqual(insights.mostRecentSavedTipName, "May Dinner")
        XCTAssertEqual(insights.mostRecentSavedTipDate, currentMonthDate)
        XCTAssertTrue(insights.hasCurrentMonthTips)
    }

    func test_savedTipInsights_shouldUseSmallerSplitCountWhenCountsTie() throws {
        _ = try makeTip(name: "Two People", people: 2)
        _ = try makeTip(name: "Four People", people: 4)

        let insights = SavedTipInsights(tips: dataManager.savedTips)

        XCTAssertEqual(insights.mostCommonSplitCount, 2)
    }

    func test_savedTipInsights_shouldUseSmallerTipPercentageWhenCountsTie() throws {
        _ = try makeTip(name: "Fifteen Percent", tipPercentage: 15)
        _ = try makeTip(name: "Twenty Percent", tipPercentage: 20)

        let insights = SavedTipInsights(tips: dataManager.savedTips)

        XCTAssertEqual(insights.mostCommonTipPercentage, 15)
    }

    func test_savedTipInsights_shouldIgnoreNilDatesWhenFindingMostRecentTip() throws {
        let recentDate = Date(timeIntervalSince1970: 1_800)
        _ = try makeTip(name: "Missing Date", date: nil)
        _ = try makeTip(name: "Recent Date", date: recentDate)

        let insights = SavedTipInsights(tips: dataManager.savedTips)

        XCTAssertEqual(insights.mostRecentSavedTipName, "Recent Date")
        XCTAssertEqual(insights.mostRecentSavedTipDate, recentDate)
    }

    func test_savedTipInsights_shouldReturnDefaultsForEmptyInput() {
        let insights = SavedTipInsights(tips: [])

        XCTAssertEqual(insights.currentMonthTotalWithTip, 0)
        XCTAssertEqual(insights.currentMonthTipTotal, 0)
        XCTAssertEqual(insights.currentMonthSavedTipCount, 0)
        XCTAssertEqual(insights.allTimeSavedTipCount, 0)
        XCTAssertEqual(insights.allTimeTotalWithTip, 0)
        XCTAssertEqual(insights.allTimeTipTotal, 0)
        XCTAssertEqual(insights.averageBillAmount, 0)
        XCTAssertEqual(insights.averageTipPercentage, 0)
        XCTAssertEqual(insights.mostCommonSplitCount, 0)
        XCTAssertEqual(insights.mostCommonTipPercentage, 0)
        XCTAssertEqual(insights.largestSavedBill, 0)
        XCTAssertNil(insights.largestSavedBillName)
        XCTAssertEqual(insights.highestTipPercentage, 0)
        XCTAssertNil(insights.highestTipName)
        XCTAssertNil(insights.mostRecentSavedTipName)
        XCTAssertNil(insights.mostRecentSavedTipDate)
        XCTAssertFalse(insights.hasCurrentMonthTips)
    }

    func test_savedTipInsights_shouldShowEmptyMonthWhenSavedTipsAreOlder() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 22).date!
        let oldDate = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 4, day: 30).date!

        _ = try makeTip(name: "Old Dinner", tipPercentage: 18, total: 80, tipAmount: 12, people: 3, date: oldDate)

        let insights = SavedTipInsights(tips: dataManager.savedTips, now: now, calendar: calendar)

        XCTAssertEqual(insights.currentMonthTotalWithTip, 0)
        XCTAssertEqual(insights.currentMonthTipTotal, 0)
        XCTAssertEqual(insights.currentMonthSavedTipCount, 0)
        XCTAssertEqual(insights.allTimeSavedTipCount, 1)
        XCTAssertEqual(insights.averageTipPercentage, 18)
        XCTAssertEqual(insights.mostCommonSplitCount, 3)
        XCTAssertEqual(insights.largestSavedBill, 80)
        XCTAssertFalse(insights.hasCurrentMonthTips)
    }

    private func makeTip(name: String,
                         tipPercentage: Double = 18,
                         total: Double = 42,
                         tipAmount: Double? = nil,
                         people: Int = 1,
                         date: Date? = Date()) throws -> SavedTip {
        let resolvedTipAmount = tipAmount ?? total * tipPercentage / 100
        let result = dataManager.saveTip(name: name,
                                         billAmount: total,
                                         tipPercentage: tipPercentage,
                                         numberOfPeople: people,
                                         tipAmount: resolvedTipAmount,
                                         totalAmountWithTip: total,
                                         totalPerPerson: total / Double(people),
                                         date: date ?? Date())

        guard case .success(let tip) = result else {
            throw XCTSkip("Could not create saved tip fixture.")
        }

        if date == nil {
            tip.date = nil
        }

        return tip
    }
}
