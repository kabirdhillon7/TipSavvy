//
//  HistoryView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/8/23.
//

import SwiftUI

/// A view that displays a list of saved tip calculations, or a message indicating that there are no saved tip calculations.
struct SavedView: View {
    @EnvironmentObject var dataManager: DataManager

    private let dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    
    var body: some View {
        NavigationStack {
            if dataManager.savedTips.isEmpty {
                Image(systemName: "percent")
                    .fontWeight(.medium)
                    .font(.system(size: 50))
                    .foregroundColor(Color(UIColor.lightGray))
                Spacer()
                    .frame(height: 5)
                Text(String(localized: "No Saved Tips"))
                    .fontWeight(.medium)
                    .foregroundStyle(Color(UIColor.lightGray))
                    .accessibilityLabel(String(localized: "No Saved Tips"))
                    .navigationTitle(String(localized: "Saved Tips"))
            } else {
                List() {
                    ForEach(dataManager.savedTips) { tip in
                        DisclosureGroup() {
                            SavedDetailView(tip: tip)
                        } label: {
                            savedTipRow(for: tip)
                        }
                    }.onDelete { indexSet in
                        dataManager.deleteTips(at: indexSet)
                    }
                }
                .toolbar {
                    EditButton()
                        .accessibilityLabel(String(localized: "Edit"))
                }
                .navigationTitle(String(localized: "Saved Tips"))
            }
        }
    }

    private func savedTipRow(for tip: SavedTip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(tip.name ?? String(localized: "Untitled Tip"))
                    .font(.headline)
                Spacer()
                Text(tip.totalAmountWithTip, format: .currency(code: localCurrency))
                    .fontWeight(.semibold)
            }

            HStack {
                if let date = tip.date {
                    Text(date, format: dateFormatMMDDYYYY)
                }

                Spacer()

                Text(String(localized: "Per Person"))
                Text(tip.totalPerPerson, format: .currency(code: localCurrency))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SavedView()
        .environmentObject(DataManager(inMemory: true))
}
