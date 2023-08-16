//
//  SavedDetailView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/12/23.
//

import SwiftUI

struct SavedDetailView: View {
    private var tip: SavedTip
    
    private var dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    
    init(tip: SavedTip, dateFormatMMDDYYYY: Foundation.Date.FormatStyle = Date.FormatStyle.dateTime.month().day().year()) {
        self.tip = tip
        self.dateFormatMMDDYYYY = dateFormatMMDDYYYY
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            let dateLocalizedString = NSLocalizedString("date", comment: "Date accessibilityLabel")
            if let date = tip.date {
                Text(date, format: dateFormatMMDDYYYY)
                    .accessibilityLabel("\(dateLocalizedString): \(date, format: dateFormatMMDDYYYY)")
            }
            HStack {
                let billAmountLocalizedString = NSLocalizedString("bill_amount", comment: "Bill Amount")
                Text("\(billAmountLocalizedString):")
                    .bold()
                    .accessibilityLabel(billAmountLocalizedString)
                Spacer()
                Text(tip.billAmount, format: .currency(code: localCurrency))
                    .accessibilityLabel("\(tip.billAmount, format: .currency(code: localCurrency))")
            }
            HStack {
                let tipPercentageLocalizedString = NSLocalizedString("tip_percentage", comment: "Tip Percentage")
                Text("\(tipPercentageLocalizedString):")
                    .bold()
                    .accessibilityLabel(tipPercentageLocalizedString)
                Spacer()
                Text("\(Int(tip.tipPercentage))%")
                    .accessibilityLabel("\(Int(tip.tipPercentage))%")
            }

            HStack {
                let numberOfPeopleLocalizedString = NSLocalizedString("number_of_people", comment: "Number of People")
                Text("\(numberOfPeopleLocalizedString):")
                    .bold()
                    .accessibilityLabel(numberOfPeopleLocalizedString)
                Spacer()
                Text("\(tip.numberOfPeople)")
                    .accessibilityLabel("\(tip.numberOfPeople)")
            }
            HStack {
                let tipAmountLocalizedString = NSLocalizedString("tip_amount", comment: "Tip Amount")
                Text("\(tipAmountLocalizedString):")
                    .bold()
                    .accessibilityLabel(tipAmountLocalizedString)
                Spacer()
                Text(tip.tipAmount, format: .currency(code: localCurrency))
                    .accessibilityLabel("\(tip.tipAmount, format: .currency(code: localCurrency))")
            }
            HStack {
                let totalBillWithTipLocalizedString = NSLocalizedString("total_bill_with_tip", comment: "Total Bill With Tip")
                Text("\(totalBillWithTipLocalizedString):")
                    .bold()
                    .accessibilityLabel(totalBillWithTipLocalizedString)
                Spacer()
                Text(tip.totalAmountWithTip, format: .currency(code: localCurrency))
                    .accessibilityLabel("\(tip.totalAmountWithTip, format: .currency(code: localCurrency))")
            }
            HStack {
                let totalPerPersonLocalizedString = NSLocalizedString("total_per_person", comment: "Total Per Person")
                Text("\(totalPerPersonLocalizedString):")
                    .bold()
                    .accessibilityLabel(totalPerPersonLocalizedString)
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
