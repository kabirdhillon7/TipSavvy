//
//  SavedTip.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/8/23.
//

import Foundation

class SavedTip: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let billAmount: Double
    let tipPercentage: Double
    let numberOfPeople: Int
    let tipAmount: Double
    let totalAmountWithTip: Double
    let totalPerPerson: Double

    init(date: Date, name: String, billAmount: Double, tipPercentage: Double, numberOfPeople: Int, tipAmount: Double, totalAmountWithTip: Double, totalPerPerson: Double) {
        self.date = date
        self.name = name
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.numberOfPeople = numberOfPeople
        self.tipAmount = tipAmount
        self.totalAmountWithTip = totalAmountWithTip
        self.totalPerPerson = totalPerPerson
    }
}

class SavedTipsEnvironment: ObservableObject {
    @Published var savedTips: [SavedTip] = []
    
    func addSavedTip(_ savedTip: SavedTip) {
        savedTips.append(savedTip)
    }
}
