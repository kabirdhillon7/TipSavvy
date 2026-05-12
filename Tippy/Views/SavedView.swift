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
    let onUseAgain: (SavedTip) -> Void

    @State private var searchText = ""
    @State private var renameText = ""
    @State private var tipBeingRenamed: SavedTip?
    @State private var tipPendingDelete: SavedTip?
    @State private var selectedTip: SavedTip?
    @State private var showingRenameAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var dataErrorMessage: String?
    @AppStorage(SavedTipListPreferenceKey.sortMode) private var sortModeRawValue = SavedTipSortMode.newest.rawValue
    @AppStorage(SavedTipListPreferenceKey.filterMode) private var filterModeRawValue = SavedTipFilterMode.all.rawValue

    private let dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"

    init(onUseAgain: @escaping (SavedTip) -> Void = { _ in }) {
        self.onUseAgain = onUseAgain
    }

    private var sortMode: SavedTipSortMode {
        get { SavedTipSortMode(rawValue: sortModeRawValue) ?? .newest }
        nonmutating set { sortModeRawValue = newValue.rawValue }
    }

    private var filterMode: SavedTipFilterMode {
        get { SavedTipFilterMode(rawValue: filterModeRawValue) ?? .all }
        nonmutating set { filterModeRawValue = newValue.rawValue }
    }

    private var sortModeBinding: Binding<SavedTipSortMode> {
        Binding(
            get: { sortMode },
            set: { sortMode = $0 }
        )
    }

    private var filterModeBinding: Binding<SavedTipFilterMode> {
        Binding(
            get: { filterMode },
            set: { filterMode = $0 }
        )
    }

    private var filteredTips: [SavedTip] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = dataManager.savedTips.filter { tip in
            let matchesSearch = trimmedSearch.isEmpty || (tip.name ?? "").localizedCaseInsensitiveContains(trimmedSearch)
            return matchesSearch && filterMode.includes(tip)
        }

        return sortMode.sort(filtered)
    }

    var body: some View {
        NavigationStack {
            Group {
                if dataManager.savedTips.isEmpty {
                    emptyState(title: String(localized: "No Saved Tips"), systemImage: "percent")
                } else {
                    VStack(spacing: 0) {
                        if let dataErrorMessage {
                            TipSavvyErrorBanner(message: dataErrorMessage) {
                                self.dataErrorMessage = nil
                                dataManager.lastError = nil
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 10)
                        }

                        activeControlsSummary
                        if filteredTips.isEmpty {
                            emptyState(title: String(localized: "No Matching Tips"), systemImage: "magnifyingglass")
                        } else {
                            savedCards
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Saved Tips"))
            .searchable(text: $searchText, prompt: String(localized: "Search Saved Tips"))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    sortMenu
                    filterMenu
                }
            }
        }
        .sheet(item: $selectedTip) { tip in
            SavedDetailView(tip: tip, onRename: renameTip, onDelete: deleteTip, onUseAgain: onUseAgain)
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
        .confirmationDialog(String(localized: "Delete Saved Tip"), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let tipPendingDelete {
                    deleteTip(tipPendingDelete)
                }
                tipPendingDelete = nil
            }

            Button(String(localized: "Cancel"), role: .cancel) {
                tipPendingDelete = nil
            }
        } message: {
            Text(String(localized: "This saved tip will be permanently deleted."))
        }
        .onChange(of: dataManager.lastError) { error in
            dataErrorMessage = error?.localizedDescription
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker(String(localized: "Sort Saved Tips"), selection: sortModeBinding) {
                ForEach(SavedTipSortMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel(String(localized: "Sort Saved Tips"))
        }
        .accessibilityIdentifier("Saved Tips Sort")
    }

    private var filterMenu: some View {
        Menu {
            Picker(String(localized: "Filter Saved Tips"), selection: filterModeBinding) {
                ForEach(SavedTipFilterMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
        } label: {
            Image(systemName: filterMode == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .accessibilityLabel(String(localized: "Filter Saved Tips"))
        }
        .accessibilityIdentifier("Saved Tips Filter")
    }

    private var activeControlsSummary: some View {
        HStack(spacing: 8) {
            Label(sortMode.title, systemImage: sortMode.systemImage)
            Label(filterMode.title, systemImage: filterMode.systemImage)
            Spacer(minLength: 8)
            Text("\(filteredTips.count)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel(String(localized: "Visible Saved Tips"))
                .accessibilityValue("\(filteredTips.count)")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 2)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("Saved Tips Controls Summary")
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
                            requestDelete(tip)
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            requestDelete(tip)
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }

                        Button {
                            startRename(for: tip)
                        } label: {
                            Label(String(localized: "Rename"), systemImage: "pencil")
                        }
                        .tint(.blue)
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
                ContentUnavailableView {
                    Label(title, systemImage: systemImage)
                } description: {
                    Text(dataManager.savedTips.isEmpty ? emptySavedDescription : emptyMatchingDescription)
                } actions: {
                    if hasActiveFiltering {
                        clearFiltersButton
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .fontWeight(.medium)
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)

                    Text(title)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    if hasActiveFiltering {
                        clearFiltersButton
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .accessibilityLabel(title)
        .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.98)))
    }

    private var hasActiveFiltering: Bool {
        filterMode != .all || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var emptySavedDescription: String {
        String(localized: "Saved calculations will appear here after you name and save them.")
    }

    private var emptyMatchingDescription: String {
        hasActiveFiltering ? String(localized: "Try a different search or filter.") : String(localized: "No saved tips match the current view.")
    }

    private var clearFiltersButton: some View {
        Button {
            searchText = ""
            filterMode = .all
        } label: {
            Label(String(localized: "Clear Filters"), systemImage: "xmark.circle")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("Clear Saved Tip Filters")
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
            _ = dataManager.renameTip(tip, to: name)
        }
    }

    private func deleteTip(_ tip: SavedTip) {
        performAnimated(.easeInOut(duration: 0.22)) {
            _ = dataManager.deleteTip(tip)
        }
    }

    private func requestDelete(_ tip: SavedTip) {
        tipPendingDelete = tip
        showingDeleteConfirmation = true
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

enum SavedTipListPreferenceKey {
    static let sortMode = "savedTipSortMode"
    static let filterMode = "savedTipFilterMode"
}

enum SavedTipSortMode: String, CaseIterable, Identifiable {
    case newest
    case name
    case total

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest:
            return String(localized: "Newest")
        case .name:
            return String(localized: "Name")
        case .total:
            return String(localized: "Total")
        }
    }

    var systemImage: String {
        switch self {
        case .newest:
            return "calendar"
        case .name:
            return "textformat"
        case .total:
            return "dollarsign.circle"
        }
    }

    func sort(_ tips: [SavedTip]) -> [SavedTip] {
        switch self {
        case .newest:
            return tips.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        case .name:
            return tips.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .total:
            return tips.sorted { $0.totalAmountWithTip > $1.totalAmountWithTip }
        }
    }
}

enum SavedTipFilterMode: String, CaseIterable, Identifiable {
    case all
    case recent
    case highTip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return String(localized: "All")
        case .recent:
            return String(localized: "Recent")
        case .highTip:
            return String(localized: "20%+")
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "tray.full"
        case .recent:
            return "clock"
        case .highTip:
            return "percent"
        }
    }

    func includes(_ tip: SavedTip) -> Bool {
        switch self {
        case .all:
            return true
        case .recent:
            guard let date = tip.date else {
                return false
            }
            return date >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        case .highTip:
            return tip.tipPercentage >= 20
        }
    }
}

#Preview {
    SavedView()
        .environmentObject(DataManager.preview)
}

#Preview("Empty Saved Tips") {
    SavedView()
        .environmentObject(DataManager.emptyPreview)
}

#Preview("Many Saved Tips") {
    SavedView()
        .environmentObject(DataManager.manyItemsPreview)
}

#Preview("Saved Tips Error") {
    SavedView()
        .environmentObject(DataManager.errorPreview)
}
