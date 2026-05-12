//
//  AppReadinessInfo.swift
//  Tippy
//
//  Created by Codex on 5/12/26.
//

import Foundation

struct AppReadinessInfo: Equatable {
    let version: String
    let build: String

    init(bundle: Bundle = .main) {
        self.version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        self.build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    init(version: String, build: String) {
        self.version = version
        self.build = build
    }

    var displayVersion: String {
        Self.displayVersion(version: version, build: build)
    }

    static func displayVersion(version: String, build: String) -> String {
        if version == build || build.isEmpty {
            return "Version \(version)"
        }

        return "Version \(version) (\(build))"
    }
}
