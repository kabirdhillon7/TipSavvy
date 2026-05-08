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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var searchText = ""
    @State private var renameText = ""
    @State private var tipBeingRenamed: SavedTip?
    @State private var showingRenameAlert = false

    private let dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"

    private var filteredTips: [SavedTip] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            return dataManager.savedTips
        }

        return dataManager.savedTips.filter { tip in
            (tip.name ?? "").localizedCaseInsensitiveContains(trimmedSearch)
        }
    }
    
    var body: some View {
        NavigationStack {
            if dataManager.savedTips.isEmpty {
                emptyState(title: String(localized: "No Saved Tips"), systemImage: "percent")
                    .navigationTitle(String(localized: "Saved Tips"))
                    .searchable(text: $searchText, prompt: String(localized: "Search Saved Tips"))
            } else if filteredTips.isEmpty {
                emptyState(title: String(localized: "No Matching Tips"), systemImage: "magnifyingglass")
                    .navigationTitle(String(localized: "Saved Tips"))
                    .searchable(text: $searchText, prompt: String(localized: "Search Saved Tips"))
            } else {
                List() {
                    ForEach(filteredTips) { tip in
                        DisclosureGroup() {
                            SavedDetailView(tip: tip)
                        } label: {
                            savedTipRow(for: tip)
                        }
                        .contextMenu {
                            Button {
                                startRename(for: tip)
                            } label: {
                                Label(String(localized: "Rename"), systemImage: "pencil")
                            }
                        }
                    }.onDelete { indexSet in
                        performAnimated(.easeInOut(duration: 0.22)) {
                            dataManager.deleteTips(indexSet.map { filteredTips[$0] })
                        }
                    }
                }
                .searchable(text: $searchText, prompt: String(localized: "Search Saved Tips"))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: filteredTips.map(\.objectID))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: searchText)
                .toolbar {
                    EditButton()
                        .accessibilityLabel(String(localized: "Edit"))
                }
                .navigationTitle(String(localized: "Saved Tips"))
            }
        }
        .alert(String(localized: "Rename Saved Tip"), isPresented: $showingRenameAlert, actions: {
            TextField(String(localized: "Enter Name"), text: $renameText)
                .autocorrectionDisabled()
                .accessibilityLabel(String(localized: "Enter Tip Calculation Name"))

            Button(String(localized: "OK")) {
                renameSavedTip()
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(String(localized: "OK"))

            Button(String(localized: "Cancel"), role: .cancel) {
                tipBeingRenamed = nil
                renameText = ""
            }
            .accessibilityLabel(String(localized: "Cancel"))
        })
    }

    private func savedTipRow(for tip: SavedTip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    savedTipName(for: tip)
                    Spacer(minLength: 12)
                    savedTipTotal(for: tip)
                }

                VStack(alignment: .leading, spacing: 2) {
                    savedTipName(for: tip)
                    savedTipTotal(for: tip)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    savedTipDate(for: tip)
                    Spacer(minLength: 12)
                    savedTipPerPerson(for: tip)
                }

                VStack(alignment: .leading, spacing: 2) {
                    savedTipDate(for: tip)
                    savedTipPerPerson(for: tip)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tip.accessibilitySummary(currencyCode: localCurrency, dateFormat: dateFormatMMDDYYYY))
        .accessibilityHint(String(localized: "Double tap to expand saved tip details"))
    }

    private func emptyState(title: String, systemImage: String) -> some View {
        Group {
            if #available(iOS 17.0, *) {
                ContentUnavailableView(title, systemImage: systemImage)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .fontWeight(.medium)
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)

                    Text(title)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityLabel(title)
        .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.98)))
    }

    private func savedTipName(for tip: SavedTip) -> some View {
        Text(tip.name ?? String(localized: "Untitled Tip"))
            .font(.headline)
    }

    private func savedTipTotal(for tip: SavedTip) -> some View {
        Text(tip.totalAmountWithTip, format: .currency(code: localCurrency))
            .fontWeight(.semibold)
            .monospacedDigit()
    }

    @ViewBuilder
    private func savedTipDate(for tip: SavedTip) -> some View {
        if let date = tip.date {
            Text(date, format: dateFormatMMDDYYYY)
        }
    }

    private func savedTipPerPerson(for tip: SavedTip) -> some View {
        Text(String(localized: "Per Person") + " " + tip.totalPerPerson.formatted(.currency(code: localCurrency)))
            .monospacedDigit()
    }

    private func startRename(for tip: SavedTip) {
        tipBeingRenamed = tip
        renameText = tip.name ?? ""
        showingRenameAlert = true
    }

    private func renameSavedTip() {
        guard let tipBeingRenamed else {
            return
        }

        performAnimated(.easeInOut(duration: 0.22)) {
            dataManager.renameTip(tipBeingRenamed, to: renameText)
        }
        self.tipBeingRenamed = nil
        renameText = ""
    }

    private func performAnimated(_ animation: Animation, _ updates: () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }
}

#Preview {
    SavedView()
        .environmentObject(DataManager(inMemory: true))
}
