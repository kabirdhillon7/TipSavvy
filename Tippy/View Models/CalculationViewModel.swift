//
//  ContentViewModel.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/16/23.
//

import Foundation
import Combine

enum RoundingMode: String, CaseIterable {
    case none
    case roundTotalUp
    case roundPerPersonUp

    var title: String {
        switch self {
        case .none:
            return String(localized: "Exact")
        case .roundTotalUp:
            return String(localized: "Total Up")
        case .roundPerPersonUp:
            return String(localized: "Person Up")
        }
    }
}

extension RoundingMode: Identifiable {
    nonisolated var id: String { rawValue }
}

struct TipComparison: Identifiable, Equatable {
    let percentage: Double
    let tipAmount: Double
    let totalAmountWithTip: Double
    let totalPerPerson: Double

    var id: Double { percentage }
}

@MainActor
final class TipSavvySettings: ObservableObject {
    @Published var defaultTipPercentage: Double {
        didSet {
            let clampedValue = Self.clampedTipPercentage(defaultTipPercentage)
            if defaultTipPercentage != clampedValue {
                defaultTipPercentage = clampedValue
                return
            }
            defaults.set(clampedValue, forKey: DefaultsKey.defaultTipPercentage)
        }
    }

    @Published var defaultNumberOfPeople: Int {
        didSet {
            let clampedValue = Self.clampedNumberOfPeople(defaultNumberOfPeople)
            if defaultNumberOfPeople != clampedValue {
                defaultNumberOfPeople = clampedValue
                return
            }
            defaults.set(clampedValue, forKey: DefaultsKey.defaultNumberOfPeople)
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: DefaultsKey.hapticsEnabled)
        }
    }

    let defaults: UserDefaults

    private enum DefaultsKey {
        static let defaultTipPercentage = "defaultTipPercentage"
        static let defaultNumberOfPeople = "defaultNumberOfPeople"
        static let hapticsEnabled = "hapticsEnabled"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedTip = defaults.object(forKey: DefaultsKey.defaultTipPercentage) as? Double ?? 18
        defaultTipPercentage = Self.clampedTipPercentage(savedTip)

        let savedPeople = defaults.object(forKey: DefaultsKey.defaultNumberOfPeople) as? Int ?? 1
        defaultNumberOfPeople = Self.clampedNumberOfPeople(savedPeople)

        hapticsEnabled = defaults.object(forKey: DefaultsKey.hapticsEnabled) as? Bool ?? true
    }

    static func clampedTipPercentage(_ percentage: Double) -> Double {
        min(max(percentage, 0), 30)
    }

    static func clampedNumberOfPeople(_ people: Int) -> Int {
        min(max(people, 1), 99)
    }

    func resetPreferences() {
        defaultTipPercentage = 18
        defaultNumberOfPeople = 1
        hapticsEnabled = true
    }
}

/// A view model responsible for managing bill information and calculating tip information.
@MainActor
final class CalculationViewModel: ObservableObject  {
    @Published var billAmount: Double?
    @Published var tipPercentage: Double
    @Published var numberOfPeople: Int
    @Published var roundingMode: RoundingMode
    @Published var tipItemName = ""

    private let defaults: UserDefaults
    private let settings: TipSavvySettings?

    private enum DefaultsKey {
        static let tipPercentage = "tipPercentage"
        static let numberOfPeople = "numberOfPeople"
        static let roundingMode = "roundingMode"
    }

    init(defaults: UserDefaults = .standard, settings: TipSavvySettings? = nil) {
        self.defaults = defaults
        self.settings = settings

        let savedTip = defaults.object(forKey: DefaultsKey.tipPercentage) as? Double
        tipPercentage = Self.clampedTipPercentage(savedTip ?? settings?.defaultTipPercentage ?? 18)

        let savedPeople = defaults.object(forKey: DefaultsKey.numberOfPeople) as? Int ?? settings?.defaultNumberOfPeople ?? 1
        numberOfPeople = Self.clampedNumberOfPeople(savedPeople)

        let savedRoundingMode = defaults.string(forKey: DefaultsKey.roundingMode)
        roundingMode = savedRoundingMode.flatMap(RoundingMode.init(rawValue:)) ?? .none
    }

    var hasValidCalculation: Bool {
        guard let billAmount = billAmount else {
            return false
        }

        return billAmount > 0 && numberOfPeople >= 1
    }

    var canSaveTip: Bool {
        hasValidCalculation && !tipItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var billValidationMessage: String? {
        guard let billAmount else {
            return String(localized: "Enter a bill amount to calculate totals.")
        }

        guard billAmount > 0 else {
            return String(localized: "Bill amount must be greater than zero.")
        }

        guard billAmount.isFinite else {
            return String(localized: "Bill amount must be a valid number.")
        }

        return nil
    }

    static func clampedTipPercentage(_ percentage: Double) -> Double {
        min(max(percentage, 0), 30)
    }

    static func clampedNumberOfPeople(_ people: Int) -> Int {
        min(max(people, 1), 99)
    }

    func persistSmartDefaults() {
        tipPercentage = Self.clampedTipPercentage(tipPercentage)
        numberOfPeople = Self.clampedNumberOfPeople(numberOfPeople)
        defaults.set(tipPercentage, forKey: DefaultsKey.tipPercentage)
        defaults.set(numberOfPeople, forKey: DefaultsKey.numberOfPeople)
        defaults.set(roundingMode.rawValue, forKey: DefaultsKey.roundingMode)
    }
    
    var tipAmount: Double {
        if let billAmount = billAmount {
            return billAmount / 100 * tipPercentage
        }
        return 0
    }
    
    var totalAmountWithTip: Double {
        switch roundingMode {
        case .none:
            return unroundedTotalAmountWithTip
        case .roundTotalUp:
            return unroundedTotalAmountWithTip.rounded(.up)
        case .roundPerPersonUp:
            guard numberOfPeople > 0 else {
                return 0
            }
            return totalPerPerson * Double(numberOfPeople)
        }
    }
    
    var totalPerPerson: Double {
        guard numberOfPeople > 0 else {
            return 0
        }

        let total = unroundedTotalAmountWithTip / Double(numberOfPeople)
        let roundedTotal: Double
        switch roundingMode {
        case .none, .roundTotalUp:
            roundedTotal = totalAmountForPeople / Double(numberOfPeople)
        case .roundPerPersonUp:
            roundedTotal = total.rounded(.up)
        }

        return Self.sanitizedAmount(roundedTotal)
    }

    var unroundedTotalForDisplay: Double {
        unroundedTotalAmountWithTip
    }

    var unroundedPerPersonForDisplay: Double {
        guard numberOfPeople > 0 else {
            return 0
        }

        return Self.sanitizedAmount(unroundedTotalAmountWithTip / Double(numberOfPeople))
    }

    func tipComparisons(for presets: [Double]) -> [TipComparison] {
        guard hasValidCalculation, let billAmount else {
            return []
        }

        return presets.map { preset in
            let tipAmount = billAmount / 100 * preset
            let unroundedTotal = Self.sanitizedAmount(billAmount + tipAmount)
            let totalPerPerson: Double
            let totalAmountWithTip: Double

            switch roundingMode {
            case .none:
                totalAmountWithTip = unroundedTotal
                totalPerPerson = Self.sanitizedAmount(unroundedTotal / Double(numberOfPeople))
            case .roundTotalUp:
                totalAmountWithTip = unroundedTotal.rounded(.up)
                totalPerPerson = Self.sanitizedAmount(totalAmountWithTip / Double(numberOfPeople))
            case .roundPerPersonUp:
                totalPerPerson = Self.sanitizedAmount((unroundedTotal / Double(numberOfPeople)).rounded(.up))
                totalAmountWithTip = totalPerPerson * Double(numberOfPeople)
            }

            return TipComparison(percentage: preset,
                                 tipAmount: Self.sanitizedAmount(tipAmount),
                                 totalAmountWithTip: Self.sanitizedAmount(totalAmountWithTip),
                                 totalPerPerson: totalPerPerson)
        }
    }

    private var unroundedTotalAmountWithTip: Double {
        guard let billAmount else {
            return 0
        }

        return Self.sanitizedAmount(billAmount + tipAmount)
    }

    private var totalAmountForPeople: Double {
        switch roundingMode {
        case .none:
            return unroundedTotalAmountWithTip
        case .roundTotalUp:
            return unroundedTotalAmountWithTip.rounded(.up)
        case .roundPerPersonUp:
            return unroundedTotalAmountWithTip
        }
    }

    private static func sanitizedAmount(_ amount: Double) -> Double {
        amount.isNaN || amount.isInfinite ? 0 : amount
    }

    func accessibilityTotalsSummary(currencyCode: String) -> String {
        [
            String(localized: "Subtotal") + ": " + Self.currencyString(billAmount ?? 0, currencyCode: currencyCode),
            String(localized: "Tip") + ": " + Self.currencyString(tipAmount, currencyCode: currencyCode),
            String(localized: "Total With Tip") + ": " + Self.currencyString(totalAmountWithTip, currencyCode: currencyCode),
            String(localized: "Total Per Person") + ": " + Self.currencyString(totalPerPerson, currencyCode: currencyCode)
        ].joined(separator: ", ")
    }

    private static func currencyString(_ amount: Double, currencyCode: String) -> String {
        amount.formatted(.currency(code: currencyCode))
    }
    
    /// Resets the tip calculation values.
    func resetValues() {
        billAmount = nil
        tipPercentage = settings?.defaultTipPercentage ?? 18
        numberOfPeople = settings?.defaultNumberOfPeople ?? 1
        roundingMode = .none
        tipItemName = ""
        persistSmartDefaults()
    }

    func applySettingsDefaults(defaultTipPercentage: Double? = nil, defaultNumberOfPeople: Int? = nil) {
        tipPercentage = defaultTipPercentage ?? settings?.defaultTipPercentage ?? tipPercentage
        numberOfPeople = defaultNumberOfPeople ?? settings?.defaultNumberOfPeople ?? numberOfPeople
        persistSmartDefaults()
    }
}

enum TipSavvyKeyboardField: Int, Hashable {
    case billAmount
}
