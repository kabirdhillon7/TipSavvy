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

struct CalculateTipIntent: AppIntent {
    static var title: LocalizedStringResource = "Calculate Tip"
    static var description = IntentDescription("Calculate a tip total and per-person amount without saving it.")

    @Parameter(title: "Bill Amount")
    var billAmount: Double

    @Parameter(title: "Tip Percentage", default: 20)
    var tipPercentage: Double

    @Parameter(title: "Number of People", default: 1)
    var numberOfPeople: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let summary = Self.summary(billAmount: billAmount,
                                   tipPercentage: tipPercentage,
                                   numberOfPeople: numberOfPeople,
                                   currencyCode: Locale.current.currency?.identifier ?? "USD")
        return .result(dialog: IntentDialog(stringLiteral: summary))
    }

    static func summary(billAmount: Double,
                        tipPercentage: Double,
                        numberOfPeople: Int,
                        currencyCode: String) -> String {
        let safeBill = billAmount.isFinite ? max(0, billAmount) : 0
        let safeTipPercentage = min(max(tipPercentage.isFinite ? tipPercentage : 0, 0), 30)
        let safePeople = min(max(numberOfPeople, 1), 99)
        let tipAmount = safeBill / 100 * safeTipPercentage
        let total = safeBill + tipAmount
        let perPerson = total / Double(safePeople)

        return String(localized: "Tip \(tipAmount.formatted(.currency(code: currencyCode))), total \(total.formatted(.currency(code: currencyCode))), \(perPerson.formatted(.currency(code: currencyCode))) per person.")
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
        AppShortcut(
            intent: CalculateTipIntent(),
            phrases: [
                "Calculate tip with \(.applicationName)",
                "Tip total with \(.applicationName)",
                "Split a tip with \(.applicationName)"
            ],
            shortTitle: "Calculate Tip",
            systemImageName: "dollarsign.circle"
        )
    }
}
