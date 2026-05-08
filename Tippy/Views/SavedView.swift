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
                        withAnimation(.easeInOut(duration: 0.22)) {
                            dataManager.deleteTips(indexSet.map { filteredTips[$0] })
                        }
                    }
                }
                .searchable(text: $searchText, prompt: String(localized: "Search Saved Tips"))
                .animation(.easeInOut(duration: 0.22), value: filteredTips.map(\.objectID))
                .animation(.easeInOut(duration: 0.18), value: searchText)
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

    private func emptyState(title: String, systemImage: String) -> some View {
        Group {
            if #available(iOS 17.0, *) {
                ContentUnavailableView(title, systemImage: systemImage)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .fontWeight(.medium)
                        .font(.system(size: 50))
                        .foregroundColor(Color(UIColor.lightGray))

                    Text(title)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(UIColor.lightGray))
                }
            }
        }
        .accessibilityLabel(title)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
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

        withAnimation(.easeInOut(duration: 0.22)) {
            dataManager.renameTip(tipBeingRenamed, to: renameText)
        }
        self.tipBeingRenamed = nil
        renameText = ""
    }
}

#Preview {
    SavedView()
        .environmentObject(DataManager(inMemory: true))
}
