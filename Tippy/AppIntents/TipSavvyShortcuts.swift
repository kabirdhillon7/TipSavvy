//
//  TipSavvyShortcuts.swift
//  Tippy
//
//  Created by Codex on 5/12/26.
//

import AppIntents

struct OpenTipSavvyCalculatorIntent: AppIntent {
    static var title: LocalizedStringResource = "Open TipSavvy Calculator"
    static var description = IntentDescription("Open TipSavvy to calculate, split, and save a tip.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct TipSavvyShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTipSavvyCalculatorIntent(),
            phrases: [
                "Open \(.applicationName) calculator",
                "Calculate a tip in \(.applicationName)",
                "Split a bill with \(.applicationName)"
            ],
            shortTitle: "Open Calculator",
            systemImageName: "percent"
        )
    }
}
