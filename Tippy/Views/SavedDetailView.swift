//
//  SavedDetailView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/12/23.
//

import SwiftUI

/// A view that displays the details of a saved tip calculation.
struct SavedDetailView: View {
    @StateObject var viewModel: SavedDetailViewModel
    
    init(tip: SavedTip) {
        self._viewModel = StateObject(wrappedValue: SavedDetailViewModel(tip: tip))
    }
    
    // MARK: Formatting
    private let dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    
    var body: some View {
        VStack(alignment: .leading) {
            let tip = viewModel.tip
            
            if let date = viewModel.tip.date {
                Text(date, format: dateFormatMMDDYYYY)
                    .accessibilityLabel("\(date, format: dateFormatMMDDYYYY)")
            }
            HStack {
                Text(String(localized: "Bill Amount") + ":")
                    .bold()
                    .accessibilityLabel(String(localized: "Bill Amount"))
                Spacer()
                Text(tip.billAmount, format: .currency(code: localCurrency))
                    .accessibilityLabel("\(tip.billAmount, format: .currency(code: localCurrency))")
            }
            HStack {
                Text(String(localized: "Tip Percentage") + ":")
                    .bold()
                    .accessibilityLabel(String(localized: "Tip Percentage"))
                Spacer()
                Text("\(Int(tip.tipPercentage))%")
                    .accessibilityLabel("\(Int(tip.tipPercentage))%")
            }

            HStack {
                Text(String(localized: "Number of People") + ":")
                    .bold()
                    .accessibilityLabel(String(localized: "Number of People"))
                Spacer()
                Text("\(tip.numberOfPeople)")
                    .accessibilityLabel("\(tip.numberOfPeople)")
            }
            HStack {
                Text(String(localized: "Tip Amount") + ":")
                    .bold()
                    .accessibilityLabel(String(localized: "Tip Amount"))
                Spacer()
                Text(tip.tipAmount, format: .currency(code: localCurrency))
                    .accessibilityLabel("\(tip.tipAmount, format: .currency(code: localCurrency))")
            }
            HStack {
                Text(String(localized: "Total Bill With Tip") + ":")
                    .bold()
                    .accessibilityLabel(String(localized: "Total Bill With Tip"))
                Spacer()
                Text(tip.totalAmountWithTip, format: .currency(code: localCurrency))
                    .accessibilityLabel("\(tip.totalAmountWithTip, format: .currency(code: localCurrency))")
            }
            HStack {
                Text(String(localized: "Total Per Person") + ":")
                    .bold()
                    .accessibilityLabel(String(localized: "Total Per Person"))
                Spacer()
                Text(tip.totalPerPerson, format: .currency(code: localCurrency))
                    .accessibilityLabel("\(tip.totalPerPerson, format: .currency(code: localCurrency))")
            }
        }
    }
}

//struct SavedDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedDetailView(tip: <#SavedTip#>)
//    }
//}
