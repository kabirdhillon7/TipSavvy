//
//  SavedDetailView.swift
//  TipSavvy
//
//  Created by Kabir Dhillon on 6/12/23.
//

import SwiftUI
import UIKit

/// A view that displays the details of a saved tip calculation.
struct SavedDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: TipSavvySettings
    @StateObject var viewModel: SavedDetailViewModel

    let onRename: (SavedTip, String) -> Void
    let onDelete: (SavedTip) -> Void
    let onUseAgain: (SavedTip) -> Void

    @State private var renameText = ""
    @State private var showingRenameAlert = false

    init(tip: SavedTip,
         onRename: @escaping (SavedTip, String) -> Void = { _, _ in },
         onDelete: @escaping (SavedTip) -> Void = { _ in },
         onUseAgain: @escaping (SavedTip) -> Void = { _ in }) {
        self._viewModel = StateObject(wrappedValue: SavedDetailViewModel(tip: tip))
        self.onRename = onRename
        self.onDelete = onDelete
        self.onUseAgain = onUseAgain
    }

    private let dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    private var shareText: String {
        viewModel.tip.shareText(currencyCode: localCurrency, dateFormat: dateFormatMMDDYYYY)
    }

    private var accentColor: Color { settings.selectedTheme.accentColor }
    private var tip: SavedTip { viewModel.tip }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    receiptCard
                    noteCard
                    useAgainButton
                }
                .padding(18)
                .padding(.bottom, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Saved Tip Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SheetCloseButton {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("Share")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    moreMenu
                }
            }
        }
        .alert(String(localized: "Rename Saved Tip"), isPresented: $showingRenameAlert, actions: {
            TextField(String(localized: "Enter Name"), text: $renameText)
                .autocorrectionDisabled()
                .accessibilityLabel(String(localized: "Enter Tip Calculation Name"))

            Button(String(localized: "OK")) {
                onRename(tip, renameText)
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(String(localized: "OK"))

            Button(String(localized: "Cancel"), role: .cancel) { }
                .accessibilityLabel(String(localized: "Cancel"))
        })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tip.name ?? String(localized: "Untitled Tip"))
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(3)

            if let date = tip.date {
                Text(date.formatted(dateFormatMMDDYYYY))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(String(localized: "Date"))
                    .accessibilityValue("\(date, format: dateFormatMMDDYYYY)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    /// The calculation as a receipt: each line adds up to the next, ending at what each person owes.
    private var receiptCard: some View {
        let percent = "\(Int(tip.tipPercentage))%"
        let tipTitle = tip.hasTaxBreakdown && tip.savedTipsOnTax
            ? String(localized: "Tip \(percent) of Subtotal + Tax")
            : String(localized: "Tip \(percent)")
        let people = Int(tip.numberOfPeople)

        return VStack(spacing: 10) {
            if tip.hasTaxBreakdown {
                InfoRow(title: String(localized: "Subtotal"), value: tip.savedSubtotalAmount.formatted(.currency(code: localCurrency)))
                InfoRow(title: String(localized: "Tax"), value: tip.savedTaxAmount.formatted(.currency(code: localCurrency)))
            } else {
                InfoRow(title: String(localized: "Bill Amount"), value: tip.billAmount.formatted(.currency(code: localCurrency)))
            }
            InfoRow(title: tipTitle, value: tip.tipAmount.formatted(.currency(code: localCurrency)))

            Divider()

            receiptTotalRow(title: String(localized: "Total With Tip"),
                            value: tip.totalAmountWithTip.formatted(.currency(code: localCurrency)),
                            emphasized: people <= 1)

            if people > 1 {
                receiptTotalRow(title: String(localized: "Split \(people) ways"),
                                value: String(localized: "\(tip.totalPerPerson.formatted(.currency(code: localCurrency))) each"),
                                emphasized: true)
            }
        }
        .padding(18)
        .contentCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Saved Tip Receipt")
    }

    private func receiptTotalRow(title: String, value: String, emphasized: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            Text(value)
                .font(emphasized ? .title2.weight(.bold) : .headline)
                .foregroundStyle(emphasized ? accentColor : Color.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    @ViewBuilder
    private var noteCard: some View {
        if let note = tip.note, !note.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Note"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(note)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .contentCard()
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("Receipt Note")
        }
    }

    private var useAgainButton: some View {
        Button {
            onUseAgain(tip)
            dismiss()
        } label: {
            Label(String(localized: "Use Again"), systemImage: "arrow.counterclockwise")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .glassProminentButtonStyle()
        .controlSize(.large)
        .tint(accentColor)
        .accessibilityLabel(String(localized: "Use Again"))
        .accessibilityIdentifier("Use Saved Tip Again")
    }

    private var moreMenu: some View {
        Menu {
            Button {
                renameText = tip.name ?? ""
                showingRenameAlert = true
            } label: {
                Label(String(localized: "Rename"), systemImage: "pencil")
            }

            Button(role: .destructive) {
                // The list offers an undo toast, so delete immediately rather than confirming.
                onDelete(tip)
                dismiss()
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        } label: {
            Label(String(localized: "More"), systemImage: "ellipsis")
        }
        .accessibilityIdentifier("Saved Tip More")
    }
}

#Preview {
    let manager = DataManager.preview
    return SavedDetailView(tip: manager.savedTips[0])
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SavedDetailPreview") ?? .standard))
}
