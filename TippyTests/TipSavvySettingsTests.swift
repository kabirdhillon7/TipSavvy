//
//  TipSavvySettingsTests.swift
//  TippyTests
//
//  Created by OpenAI Codex on 5/8/26.
//

import XCTest
@testable import Tippy

@MainActor
final class TipSavvySettingsTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "TipSavvySettingsTests")
        defaults.removePersistentDomain(forName: "TipSavvySettingsTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "TipSavvySettingsTests")
        defaults = nil
        super.tearDown()
    }

    func test_defaults_shouldUseProductionStartingValues() {
        let settings = TipSavvySettings(defaults: defaults)

        XCTAssertEqual(settings.defaultTipPercentage, 18)
        XCTAssertEqual(settings.defaultNumberOfPeople, 1)
        XCTAssertTrue(settings.hapticsEnabled)
    }

    func test_savedValues_shouldRestoreOnNextLaunch() {
        let settings = TipSavvySettings(defaults: defaults)
        settings.defaultTipPercentage = 22
        settings.defaultNumberOfPeople = 4
        settings.hapticsEnabled = false

        let restoredSettings = TipSavvySettings(defaults: defaults)

        XCTAssertEqual(restoredSettings.defaultTipPercentage, 22)
        XCTAssertEqual(restoredSettings.defaultNumberOfPeople, 4)
        XCTAssertFalse(restoredSettings.hapticsEnabled)
    }

    func test_outOfRangeDefaults_shouldClampToSupportedValues() {
        defaults.set(100.0, forKey: "defaultTipPercentage")
        defaults.set(0, forKey: "defaultNumberOfPeople")

        let settings = TipSavvySettings(defaults: defaults)

        XCTAssertEqual(settings.defaultTipPercentage, 30)
        XCTAssertEqual(settings.defaultNumberOfPeople, 1)
    }

    func test_outOfRangeAssignment_shouldClampWithoutCrashing() {
        let settings = TipSavvySettings(defaults: defaults)

        settings.defaultTipPercentage = 100
        settings.defaultNumberOfPeople = 0

        XCTAssertEqual(settings.defaultTipPercentage, 30)
        XCTAssertEqual(settings.defaultNumberOfPeople, 1)
    }

    func test_resetPreferences_shouldRestoreDefaultsAndPersistThem() {
        let settings = TipSavvySettings(defaults: defaults)
        settings.defaultTipPercentage = 25
        settings.defaultNumberOfPeople = 6
        settings.hapticsEnabled = false

        settings.resetPreferences()

        XCTAssertEqual(settings.defaultTipPercentage, 18)
        XCTAssertEqual(settings.defaultNumberOfPeople, 1)
        XCTAssertTrue(settings.hapticsEnabled)

        let restoredSettings = TipSavvySettings(defaults: defaults)
        XCTAssertEqual(restoredSettings.defaultTipPercentage, 18)
        XCTAssertEqual(restoredSettings.defaultNumberOfPeople, 1)
        XCTAssertTrue(restoredSettings.hapticsEnabled)
    }
}
