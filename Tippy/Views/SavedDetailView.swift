//
//  SavedDetailView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/12/23.
//

import SwiftUI
import UIKit

/// A view that displays the details of a saved tip calculation.
struct SavedDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: SavedDetailViewModel

    let onRename: (SavedTip, String) -> Void
    let onDelete: (SavedTip) -> Void
    let onUseAgain: (SavedTip) -> Void

    @State private var renameText = ""
    @State private var showingRenameAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCopiedBanner = false

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    totalsGrid
                    useAgainButton
                    detailsCard
                    noteCard
                    shareCard
                    actionButtons
                }
                .padding(18)
                .padding(.bottom, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Saved Tip Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
            .toastOverlay(isPresented: showingCopiedBanner) {
                TipSavvySuccessBanner(message: String(localized: "Details copied"))
            }
        }
        .alert(String(localized: "Rename Saved Tip"), isPresented: $showingRenameAlert, actions: {
            TextField(String(localized: "Enter Name"), text: $renameText)
                .autocorrectionDisabled()
                .accessibilityLabel(String(localized: "Enter Tip Calculation Name"))

            Button(String(localized: "OK")) {
                onRename(viewModel.tip, renameText)
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(String(localized: "OK"))

            Button(String(localized: "Cancel"), role: .cancel) { }
                .accessibilityLabel(String(localized: "Cancel"))
        })
        .confirmationDialog(String(localized: "Delete Saved Tip"), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(String(localized: "Delete"), role: .destructive) {
                onDelete(viewModel.tip)
                dismiss()
            }

            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "This saved tip will be permanently deleted."))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.tip.name ?? String(localized: "Untitled Tip"))
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(3)

            if let date = viewModel.tip.date {
                Label(date.formatted(dateFormatMMDDYYYY), systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(String(localized: "Date"))
                    .accessibilityValue("\(date, format: dateFormatMMDDYYYY)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 24)
    }

    private var totalsGrid: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                MetricCard(title: String(localized: "Total Per Person"), value: viewModel.tip.totalPerPerson.formatted(.currency(code: localCurrency)), prominence: .primary)
                MetricCard(title: String(localized: "Total With Tip"), value: viewModel.tip.totalAmountWithTip.formatted(.currency(code: localCurrency)))
            }

            VStack(spacing: 12) {
                MetricCard(title: String(localized: "Total Per Person"), value: viewModel.tip.totalPerPerson.formatted(.currency(code: localCurrency)), prominence: .primary)
                MetricCard(title: String(localized: "Total With Tip"), value: viewModel.tip.totalAmountWithTip.formatted(.currency(code: localCurrency)))
            }
        }
    }

    private var detailsCard: some View {
        VStack(spacing: 12) {
            InfoRow(title: String(localized: "Bill Amount"), value: viewModel.tip.billAmount.formatted(.currency(code: localCurrency)))
            if viewModel.tip.hasTaxBreakdown {
                Divider()
                InfoRow(title: String(localized: "Subtotal"), value: viewModel.tip.savedSubtotalAmount.formatted(.currency(code: localCurrency)))
                Divider()
                InfoRow(title: String(localized: "Tax"), value: viewModel.tip.savedTaxAmount.formatted(.currency(code: localCurrency)))
                Divider()
                InfoRow(title: String(localized: "Tip Basis"), value: viewModel.tip.savedTipsOnTax ? String(localized: "Subtotal + Tax") : String(localized: "Subtotal"))
            }
            Divider()
            InfoRow(title: String(localized: "Tip Percentage"), value: "\(Int(viewModel.tip.tipPercentage))%")
            Divider()
            InfoRow(title: String(localized: "Number of People"), value: "\(viewModel.tip.numberOfPeople)")
            Divider()
            InfoRow(title: String(localized: "Tip Amount"), value: viewModel.tip.tipAmount.formatted(.currency(code: localCurrency)))
        }
        .padding(18)
        .glassPanel(cornerRadius: 22)
    }

    @ViewBuilder
    private var noteCard: some View {
        if let note = viewModel.tip.note, !note.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(String(localized: "Receipt Note"), systemImage: "note.text")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(note)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassPanel(cornerRadius: 22)
            .accessibilityIdentifier("Receipt Note")
        }
    }

    private var shareCard: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                copyDetailsButton
                ShareLink(item: shareText) {
                    Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            VStack(spacing: 12) {
                copyDetailsButton
                ShareLink(item: shareText) {
                    Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var copyDetailsButton: some View {
        Button {
            UIPasteboard.general.string = shareText
            showingCopiedBanner = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                await MainActor.run { showingCopiedBanner = false }
            }
        } label: {
            Label(String(localized: "Copy Details"), systemImage: "doc.on.doc")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(String(localized: "Copy Details"))
    }

    private var useAgainButton: some View {
        Button {
            onUseAgain(viewModel.tip)
            dismiss()
        } label: {
            Label(String(localized: "Use Again"), systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityLabel(String(localized: "Use Again"))
        .accessibilityIdentifier("Use Saved Tip Again")
    }

    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                renameButton
                deleteButton
            }

            VStack(spacing: 12) {
                renameButton
                deleteButton
            }
        }
    }

    private var renameButton: some View {
        Button {
            renameText = viewModel.tip.name ?? ""
            showingRenameAlert = true
        } label: {
            Label(String(localized: "Rename"), systemImage: "pencil")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(String(localized: "Rename"))
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label(String(localized: "Delete"), systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(String(localized: "Delete"))
    }
}

#Preview {
    let manager = DataManager.preview
    return SavedDetailView(tip: manager.savedTips[0])
}
