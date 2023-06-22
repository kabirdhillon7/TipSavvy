//
//  SavedDetailView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/12/23.
//

import SwiftUI

struct SavedDetailView: View {
    var tip: SavedTip
    
    var body: some View {
        VStack(alignment: .leading) {
            if let date = tip.date {
                Text(date, format: .dateTime.month().day().year())
            }
            HStack {
                Text("Bill Amount:")
                    .bold()
                Spacer()
                Text(tip.billAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
            }
            HStack {
                Text("Tip Percentage:")
                    .bold()
                Spacer()
                Text("\(Int(tip.tipPercentage))%")
            }

            HStack {
                Text("Number of People:")
                    .bold()
                Spacer()
                Text("\(tip.numberOfPeople)")
            }
            HStack {
                Text("Tip Amount:")
                    .bold()
                Spacer()
                Text(tip.tipAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
            }
            HStack {
                Text("Total Bill With Tip:")
                    .bold()
                Spacer()
                Text(tip.totalAmountWithTip, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
            }
            HStack {
                Text("Total Per Person:")
                    .bold()
                Spacer()
                Text(tip.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.body)
            }
        }
    }
}

//struct SavedDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedDetailView(tip: <#SavedTip#>)
//    }
//}
