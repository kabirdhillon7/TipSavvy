//
//  ContentViewModel.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/16/23.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject  {    
    @Published var billAmount: Double?
    @Published var tipPercentage = 0.0
    @Published var numberOfPeople: Int?
    @Published var tipItemName = ""
    
//    var tipAmount: Double {
//        return billAmount / 100 * tipPercentage
//    }
//    var totalAmountWithTip: Double {
//        let tipValue = billAmount / 100 * tipPercentage
//
//        return billAmount + tipValue
//    }
//
//    var totalPerPerson: Double {
//        let people = Double(numberOfPeople)
//        let tipValue = billAmount / 100 * tipPercentage
//        let totalBillPlusTip = billAmount + tipValue
//
//        var total = totalBillPlusTip / people
//
//        if people != 0 {
//            total = totalBillPlusTip / people
//        }
//
//        if total.isNaN || total.isInfinite {
//            total = 0
//        }
//
//        return total
//    }
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
        if let billAmount = billAmount, let people = numberOfPeople, people != 0 {
            let numOfPeople = Double(people)
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
}
