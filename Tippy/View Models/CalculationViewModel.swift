//
//  ContentViewModel.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/16/23.
//

import Foundation
import Combine

/// A view model responsible for managing bill information and calculating tip information.
final class CalculationViewModel: ObservableObject  {
    @Published var billAmount: Double?
    @Published var tipPercentage: Double
    @Published var numberOfPeople: Int
    @Published var tipItemName = ""

    private let defaults: UserDefaults

    private enum DefaultsKey {
        static let tipPercentage = "tipPercentage"
        static let numberOfPeople = "numberOfPeople"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        tipPercentage = Self.clampedTipPercentage(defaults.double(forKey: DefaultsKey.tipPercentage))

        let savedPeople = defaults.object(forKey: DefaultsKey.numberOfPeople) as? Int ?? 1
        numberOfPeople = Self.clampedNumberOfPeople(savedPeople)
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
    }
    
    var tipAmount: Double {
        if let billAmount = billAmount {
            return billAmount / 100 * tipPercentage
        }
        return 0
    }
    
    var totalAmountWithTip: Double {
        if let billAmount = billAmount {
            let tipValue = billAmount / 100 * tipPercentage
            return billAmount + tipValue
        }
        return 0
    }
    
    var totalPerPerson: Double {
        if let billAmount = billAmount, numberOfPeople != 0 {
            let numOfPeople = Double(numberOfPeople)
            let tipValue = billAmount / 100 * tipPercentage
            let totalBillPlusTip = billAmount + tipValue
            var total = totalBillPlusTip / numOfPeople
            
            if total.isNaN || total.isInfinite {
                total = 0
            }
            
            return total
        }
        return 0
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
        tipPercentage = 0
        numberOfPeople = 1
        tipItemName = ""
        persistSmartDefaults()
    }
}

enum TipSavvyKeyboardField: Int, Hashable {
    case billAmount
}
