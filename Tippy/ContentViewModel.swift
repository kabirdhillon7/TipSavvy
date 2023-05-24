//
//  ContentViewModel.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/16/23.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject  {
    @Published var billAmount = 0.0
    @Published var tipPercentage = 0.0
    @Published var numberOfPeople = 0
    
    var totalAmountWithTip: Double {
        let tipValue = billAmount / 100 * tipPercentage
        
        return billAmount + tipValue
    }
    
    var totalPerPerson: Double {
        let people = Double(numberOfPeople)
        let tipValue = billAmount / 100 * tipPercentage
        let totalBillPlusTip = billAmount + tipValue
        
        var total = totalBillPlusTip / people
        
        if people != 0 {
            total = totalBillPlusTip / people
        }
        
        if total.isNaN || total.isInfinite {
            total = 0
        }
        
        return total
    }
}
