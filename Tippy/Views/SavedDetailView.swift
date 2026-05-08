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
        VStack(alignment: .leading, spacing: 8) {
            let tip = viewModel.tip
            
            if let date = viewModel.tip.date {
                Text(date, format: dateFormatMMDDYYYY)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(String(localized: "Date"))
                    .accessibilityValue("\(date, format: dateFormatMMDDYYYY)")
            }

            detailRow(title: String(localized: "Bill Amount"), value: tip.billAmount.formatted(.currency(code: localCurrency)))
            detailRow(title: String(localized: "Tip Percentage"), value: "\(Int(tip.tipPercentage))%")
            detailRow(title: String(localized: "Number of People"), value: "\(tip.numberOfPeople)")
            detailRow(title: String(localized: "Tip Amount"), value: tip.tipAmount.formatted(.currency(code: localCurrency)))
            detailRow(title: String(localized: "Total Bill With Tip"), value: tip.totalAmountWithTip.formatted(.currency(code: localCurrency)))
            detailRow(title: String(localized: "Total Per Person"), value: tip.totalPerPerson.formatted(.currency(code: localCurrency)))
        }
        .padding(.vertical, 4)
    }

    private func detailRow(title: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                detailTitle(title)
                Spacer(minLength: 12)
                detailValue(value)
            }

            VStack(alignment: .leading, spacing: 2) {
                detailTitle(title)
                detailValue(value)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func detailTitle(_ title: String) -> some View {
        Text(title + ":")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private func detailValue(_ value: String) -> some View {
        Text(value)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}

//struct SavedDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedDetailView(tip: <#SavedTip#>)
//    }
//}
