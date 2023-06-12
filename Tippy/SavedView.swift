//
//  HistoryView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/8/23.
//

import SwiftUI

struct SavedView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        /*
         Need a list
         need to load previous calculations
         Format: Name given, subtotal, amnt w/ tip
         
         Need an object where user
         */
        NavigationStack {
            List(dataManager.savedTips) { tip in
                VStack {
                    HStack {
                        Text(tip.name ?? "")
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

struct SavedView_Previews: PreviewProvider {
    static var previews: some View {
        SavedView()
    }
}
