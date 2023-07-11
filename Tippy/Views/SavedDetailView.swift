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
                    .accessibilityLabel("Date: \(date, format: .dateTime.month().day().year())")
            }
            HStack {
                Text("Bill Amount:")
                    .bold()
                    .accessibilityLabel("Bill Amount")
                Spacer()
                Text(tip.billAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .accessibilityLabel("\(tip.billAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
            }
            HStack {
                Text("Tip Percentage:")
                    .bold()
                    .accessibilityLabel("Tip Percentage")
                Spacer()
                Text("\(Int(tip.tipPercentage))%")
                    .accessibilityLabel("\(Int(tip.tipPercentage))%")
            }

            HStack {
                Text("Number of People:")
                    .bold()
                    .accessibilityLabel("Number of People")
                Spacer()
                Text("\(tip.numberOfPeople)")
                    .accessibilityLabel("\(tip.numberOfPeople)")
            }
            HStack {
                Text("Tip Amount:")
                    .bold()
                    .accessibilityLabel("Tip Amount")
                Spacer()
                Text(tip.tipAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .accessibilityLabel("\(tip.tipAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
            }
            HStack {
                Text("Total Bill With Tip:")
                    .bold()
                    .accessibilityLabel("Total Bill With Tip")
                Spacer()
                Text(tip.totalAmountWithTip, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .accessibilityLabel("\(tip.totalAmountWithTip, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
            }
            HStack {
                Text("Total Per Person:")
                    .bold()
                    .accessibilityLabel("Total Per Person")
                Spacer()
                Text(tip.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .accessibilityLabel("\(tip.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
            }
        }
    }
}

//struct SavedDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedDetailView(tip: <#SavedTip#>)
//    }
//}
