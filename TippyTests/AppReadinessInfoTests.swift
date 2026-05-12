//
//  AppReadinessInfoTests.swift
//  TippyTests
//
//  Created by Codex on 5/12/26.
//

import XCTest
@testable import Tippy

final class AppReadinessInfoTests: XCTestCase {
    func test_displayVersion_shouldIncludeBuildWhenDifferentFromMarketingVersion() {
        let info = AppReadinessInfo(version: "3.7", build: "42")

        XCTAssertEqual(info.displayVersion, "Version 3.7 (42)")
    }

    func test_displayVersion_shouldOmitBuildWhenItMatchesMarketingVersion() {
        let info = AppReadinessInfo(version: "3.7", build: "3.7")

        XCTAssertEqual(info.displayVersion, "Version 3.7")
    }

    func test_displayVersion_shouldOmitEmptyBuild() {
        XCTAssertEqual(AppReadinessInfo.displayVersion(version: "3.7", build: ""), "Version 3.7")
    }
}
