//
//  HistoryView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/8/23.
//

import SwiftUI

struct SavedView: View {
    @EnvironmentObject var savedTipsEnvironment: SavedTipsEnvironment
    
    var body: some View {
        /*
         Need a list
         need to load previous calculations
         Format: Name given, subtotal, amnt w/ tip
         
         Need an object where user
         */
        NavigationStack {
            List(savedTipsEnvironment.savedTips) { tip in
                VStack {
                    HStack {
                        Text(tip.name)
                        Spacer()
                        Text(tip.billAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        Spacer()
                        Text(tip.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                }
            }
            .navigationTitle("Saved Tips")
        }
    }
}

//struct HistoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedView()
//            .environmentObject(SavedTipsEnvironment())
//    }
//}
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let savedTipsEnvironment = SavedTipsEnvironment()
        
        // Add some sample saved tips
        savedTipsEnvironment.savedTips = [
            SavedTip(date: Date(), name: "Tip 1", billAmount: 50.0, tipPercentage: 15.0, numberOfPeople: 2, tipAmount: 7.5, totalAmountWithTip: 57.5, totalPerPerson: 28.75),
            SavedTip(date: Date(), name: "Tip 2", billAmount: 100.0, tipPercentage: 20.0, numberOfPeople: 4, tipAmount: 20.0, totalAmountWithTip: 120.0, totalPerPerson: 30.0)
        ]
        
        return SavedView()
            .environmentObject(savedTipsEnvironment)
    }
}
