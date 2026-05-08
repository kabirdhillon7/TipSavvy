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
    @Published var tipPercentage = 0.0
    @Published var numberOfPeople = 1
    @Published var tipItemName = ""

    var hasValidCalculation: Bool {
        guard let billAmount = billAmount else {
            return false
        }

        return billAmount > 0 && numberOfPeople >= 1
    }

    var canSaveTip: Bool {
        hasValidCalculation && !tipItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
    
    /// Resets the tip calculation values.
    func resetValues() {
        billAmount = nil
        tipPercentage = 0
        numberOfPeople = 1
        tipItemName = ""
    }
}

enum TipSavvyKeyboardField: Int, Hashable {
    case billAmount
}
