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
    @State private var selectedTip: SavedTip?
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
            Group {
                if dataManager.savedTips.isEmpty {
                    emptyState(title: String(localized: "No Saved Tips"), systemImage: "percent")
                } else if filteredTips.isEmpty {
                    emptyState(title: String(localized: "No Matching Tips"), systemImage: "magnifyingglass")
                } else {
                    savedCards
                }
            }
            .navigationTitle(String(localized: "Saved Tips"))
            .searchable(text: $searchText, prompt: String(localized: "Search Saved Tips"))
        }
        .sheet(item: $selectedTip) { tip in
            SavedDetailView(tip: tip, onRename: renameTip, onDelete: deleteTip)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

    private var savedCards: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(filteredTips) { tip in
                    Button {
                        selectedTip = tip
                    } label: {
                        savedTipCard(for: tip)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            startRename(for: tip)
                        } label: {
                            Label(String(localized: "Rename"), systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            performAnimated(.easeInOut(duration: 0.22)) {
                                dataManager.deleteTip(tip)
                            }
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: filteredTips.map(\.objectID))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: searchText)
    }

    private func savedTipCard(for tip: SavedTip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    savedTipName(for: tip)
                    Spacer(minLength: 12)
                    savedTipTotal(for: tip)
                }

                VStack(alignment: .leading, spacing: 4) {
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

                VStack(alignment: .leading, spacing: 4) {
                    savedTipDate(for: tip)
                    savedTipPerPerson(for: tip)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label("\(Int(tip.tipPercentage))%", systemImage: "percent")
                Label("\(tip.numberOfPeople)", systemImage: "person.2")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(cornerRadius: 22, interactive: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tip.accessibilitySummary(currencyCode: localCurrency, dateFormat: dateFormatMMDDYYYY))
        .accessibilityHint(String(localized: "Opens saved tip details"))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .accessibilityLabel(title)
        .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.98)))
    }

    private func savedTipName(for tip: SavedTip) -> some View {
        Text(tip.name ?? String(localized: "Untitled Tip"))
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(2)
    }

    private func savedTipTotal(for tip: SavedTip) -> some View {
        Text(tip.totalAmountWithTip, format: .currency(code: localCurrency))
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
            .monospacedDigit()
            .animatedTextChange(value: tip.totalAmountWithTip)
    }

    @ViewBuilder
    private func savedTipDate(for tip: SavedTip) -> some View {
        if let date = tip.date {
            Label(date.formatted(dateFormatMMDDYYYY), systemImage: "calendar")
        }
    }

    private func savedTipPerPerson(for tip: SavedTip) -> some View {
        Label(String(localized: "Per Person") + " " + tip.totalPerPerson.formatted(.currency(code: localCurrency)), systemImage: "person")
            .monospacedDigit()
            .animatedTextChange(value: tip.totalPerPerson)
    }

    private func startRename(for tip: SavedTip) {
        tipBeingRenamed = tip
        renameText = tip.name ?? ""
        showingRenameAlert = true
    }

    private func renameTip(_ tip: SavedTip, _ name: String) {
        performAnimated(.easeInOut(duration: 0.22)) {
            dataManager.renameTip(tip, to: name)
        }
    }

    private func deleteTip(_ tip: SavedTip) {
        performAnimated(.easeInOut(duration: 0.22)) {
            dataManager.deleteTip(tip)
        }
    }

    private func renameSavedTip() {
        guard let tipBeingRenamed else {
            return
        }

        renameTip(tipBeingRenamed, renameText)
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
        .environmentObject(DataManager.preview)
}
