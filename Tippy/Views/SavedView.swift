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
    @EnvironmentObject var settings: TipSavvySettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onUseAgain: (SavedTip) -> Void

    @State private var searchText = ""
    @State private var renameText = ""
    @State private var tipBeingRenamed: SavedTip?
    @State private var tipPendingDelete: SavedTip?
    @State private var selectedTip: SavedTip?
    @State private var showingSavedInsightsDetails = false
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

    private var savedInsights: SavedTipInsights {
        SavedTipInsights(tips: dataManager.savedTips)
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
                        activeControlsSummary
                        savedCards
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
            .toastOverlay(isPresented: dataErrorMessage != nil) {
                if let dataErrorMessage {
                    TipSavvyErrorBanner(message: dataErrorMessage) {
                        self.dataErrorMessage = nil
                        dataManager.lastError = nil
                    }
                }
            }
        }
        .sheet(item: $selectedTip) { tip in
            SavedDetailView(tip: tip, onRename: renameTip, onDelete: deleteTip, onUseAgain: onUseAgain)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSavedInsightsDetails) {
            SavedInsightsDetailView(insights: savedInsights, currencyCode: localCurrency)
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

    private var savedInsightsButton: some View {
        Button {
            showingSavedInsightsDetails = true
        } label: {
            savedInsightsPanel
        }
        .buttonStyle(.plain)
        .accessibilityHint(String(localized: "Shows detailed saved insights."))
        .accessibilityIdentifier("Saved Insights")
    }

    private var savedInsightsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    Label(String(localized: "Saved Insights"), systemImage: "chart.bar.xaxis")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 12)
                    Text(String(localized: "This Month"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label(String(localized: "Saved Insights"), systemImage: "chart.bar.xaxis")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "This Month"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    MetricCard(title: String(localized: "Spent This Month"), value: savedInsights.currentMonthTotalWithTip.formatted(.currency(code: localCurrency)), prominence: .primary)
                    MetricCard(title: String(localized: "Tips This Month"), value: savedInsights.currentMonthTipTotal.formatted(.currency(code: localCurrency)))
                }

                VStack(spacing: 12) {
                    MetricCard(title: String(localized: "Spent This Month"), value: savedInsights.currentMonthTotalWithTip.formatted(.currency(code: localCurrency)), prominence: .primary)
                    MetricCard(title: String(localized: "Tips This Month"), value: savedInsights.currentMonthTipTotal.formatted(.currency(code: localCurrency)))
                }
            }

            Divider()

            InfoRow(title: String(localized: "Saved Tips"), value: "\(savedInsights.allTimeSavedTipCount)")
        }
        .padding(18)
        .glassPanel(cornerRadius: 22, interactive: true)
        .accessibilityElement(children: .contain)
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
            VStack(spacing: 14) {
                savedInsightsButton

                if filteredTips.isEmpty {
                    emptyState(title: String(localized: "No Matching Tips"), systemImage: "magnifyingglass")
                        .frame(minHeight: 320)
                } else {
                    savedTipList
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

    private var savedTipList: some View {
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
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        onUseAgain(tip)
                        HapticFeedbackPerformer.success(isEnabled: settings.hapticsEnabled)
                    } label: {
                        Label(String(localized: "Use Again"), systemImage: "arrow.counterclockwise")
                    }
                    .tint(.teal)
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

struct SavedInsightsDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let insights: SavedTipInsights
    let currencyCode: String

    private let dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private var noneYetText: String { String(localized: "None Yet") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    thisMonthSection
                    allTimeSection
                    highlightsSection
                    patternsSection
                }
                .padding(18)
                .padding(.bottom, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Saved Insights"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("Saved Insights Detail")
    }

    private var thisMonthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(String(localized: "This Month"), systemImage: "calendar")

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    MetricCard(title: String(localized: "Spent This Month"), value: insights.currentMonthTotalWithTip.formatted(.currency(code: currencyCode)), prominence: .primary)
                    MetricCard(title: String(localized: "Tips This Month"), value: insights.currentMonthTipTotal.formatted(.currency(code: currencyCode)))
                }

                VStack(spacing: 12) {
                    MetricCard(title: String(localized: "Spent This Month"), value: insights.currentMonthTotalWithTip.formatted(.currency(code: currencyCode)), prominence: .primary)
                    MetricCard(title: String(localized: "Tips This Month"), value: insights.currentMonthTipTotal.formatted(.currency(code: currencyCode)))
                }
            }

            InfoRow(title: String(localized: "Saved Tips"), value: "\(insights.currentMonthSavedTipCount)")

            if !insights.hasCurrentMonthTips {
                Label(String(localized: "No saved tips from this month yet."), systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 22)
        .accessibilityIdentifier("Saved Insights This Month")
    }

    private var allTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(String(localized: "All Time"), systemImage: "sum")
            InfoRow(title: String(localized: "Total Spent"), value: insights.allTimeTotalWithTip.formatted(.currency(code: currencyCode)))
            Divider()
            InfoRow(title: String(localized: "Total Tips"), value: insights.allTimeTipTotal.formatted(.currency(code: currencyCode)))
            Divider()
            InfoRow(title: String(localized: "Average Bill"), value: insights.averageBillAmount.formatted(.currency(code: currencyCode)))
            Divider()
            InfoRow(title: String(localized: "Average Per Person"), value: insights.averagePerPersonTotal.formatted(.currency(code: currencyCode)))
            Divider()
            InfoRow(title: String(localized: "Average Tip"), value: percentageText(insights.averageTipPercentage))
            if insights.savedTipsWithTaxCount > 0 {
                Divider()
                InfoRow(title: String(localized: "Average Tax"), value: insights.averageTaxAmount.formatted(.currency(code: currencyCode)))
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 22)
        .accessibilityIdentifier("Saved Insights All Time")
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(String(localized: "Highlights"), systemImage: "sparkles")
            InfoRow(title: String(localized: "Largest Bill"), value: insights.largestSavedBill.formatted(.currency(code: currencyCode)))
            detailCaption(insights.largestSavedBillName)
            Divider()
            InfoRow(title: String(localized: "Highest Tip"), value: percentageText(insights.highestTipPercentage))
            detailCaption(insights.highestTipName)
            Divider()
            InfoRow(title: String(localized: "Most Recent"), value: insights.mostRecentSavedTipName ?? noneYetText)
            if let date = insights.mostRecentSavedTipDate {
                detailCaption(date.formatted(dateFormatMMDDYYYY))
            } else {
                detailCaption(nil)
            }
            Divider()
            InfoRow(title: String(localized: "Recent Activity"), value: insights.recentActivitySummary)
        }
        .padding(18)
        .glassPanel(cornerRadius: 22)
        .accessibilityIdentifier("Saved Insights Highlights")
    }

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(String(localized: "Patterns"), systemImage: "chart.bar")
            InfoRow(title: String(localized: "Common Split"), value: "\(insights.mostCommonSplitCount)")
            Divider()
            InfoRow(title: String(localized: "Common Tip"), value: percentageText(insights.mostCommonTipPercentage))
            if insights.savedTipsWithTaxCount > 0 {
                Divider()
                InfoRow(title: String(localized: "Saved With Tax"), value: "\(insights.savedTipsWithTaxCount)")
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 22)
        .accessibilityIdentifier("Saved Insights Patterns")
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    private func detailCaption(_ text: String?) -> some View {
        Text((text?.isEmpty == false ? text : nil) ?? noneYetText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func percentageText(_ percentage: Double) -> String {
        String(format: "%.0f%%", percentage)
    }
}

struct SavedTipInsights: Equatable {
    let currentMonthTotalWithTip: Double
    let currentMonthTipTotal: Double
    let currentMonthSavedTipCount: Int
    let allTimeSavedTipCount: Int
    let allTimeTotalWithTip: Double
    let allTimeTipTotal: Double
    let averageBillAmount: Double
    let averagePerPersonTotal: Double
    let averageTipPercentage: Double
    let averageTaxAmount: Double
    let savedTipsWithTaxCount: Int
    let mostCommonSplitCount: Int
    let mostCommonTipPercentage: Double
    let largestSavedBill: Double
    let largestSavedBillName: String?
    let highestTipPercentage: Double
    let highestTipName: String?
    let mostRecentSavedTipName: String?
    let mostRecentSavedTipDate: Date?
    let recentActivitySummary: String
    let hasCurrentMonthTips: Bool

    init(tips: [SavedTip], now: Date = Date(), calendar: Calendar = .current) {
        let monthInterval = calendar.dateInterval(of: .month, for: now)
        let currentMonthTips = tips.filter { tip in
            guard let date = tip.date, let monthInterval else {
                return false
            }

            return monthInterval.contains(date)
        }

        currentMonthTotalWithTip = currentMonthTips.reduce(0) { $0 + $1.totalAmountWithTip }
        currentMonthTipTotal = currentMonthTips.reduce(0) { $0 + $1.tipAmount }
        currentMonthSavedTipCount = currentMonthTips.count
        allTimeSavedTipCount = tips.count
        allTimeTotalWithTip = tips.reduce(0) { $0 + $1.totalAmountWithTip }
        allTimeTipTotal = tips.reduce(0) { $0 + $1.tipAmount }
        averageBillAmount = tips.isEmpty ? 0 : tips.reduce(0) { $0 + $1.billAmount } / Double(tips.count)
        averagePerPersonTotal = tips.isEmpty ? 0 : tips.reduce(0) { $0 + $1.totalPerPerson } / Double(tips.count)
        averageTipPercentage = tips.isEmpty ? 0 : tips.reduce(0) { $0 + $1.tipPercentage } / Double(tips.count)
        let tipsWithTax = tips.filter(\.hasTaxBreakdown)
        savedTipsWithTaxCount = tipsWithTax.count
        averageTaxAmount = tipsWithTax.isEmpty ? 0 : tipsWithTax.reduce(0) { $0 + $1.savedTaxAmount } / Double(tipsWithTax.count)
        mostCommonSplitCount = Self.mostCommonSplitCount(in: tips)
        mostCommonTipPercentage = Self.mostCommonTipPercentage(in: tips)
        let largestSavedTip = tips.max { lhs, rhs in
            lhs.totalAmountWithTip < rhs.totalAmountWithTip
        }
        largestSavedBill = tips.map(\.totalAmountWithTip).max() ?? 0
        largestSavedBillName = largestSavedTip?.name
        let highestTip = tips.max { lhs, rhs in
            lhs.tipPercentage < rhs.tipPercentage
        }
        highestTipPercentage = highestTip?.tipPercentage ?? 0
        highestTipName = highestTip?.name
        let mostRecentTip = tips.compactMap { tip -> (SavedTip, Date)? in
            guard let date = tip.date else {
                return nil
            }

            return (tip, date)
        }
        .max { lhs, rhs in
            lhs.1 < rhs.1
        }
        mostRecentSavedTipName = mostRecentTip?.0.name
        mostRecentSavedTipDate = mostRecentTip?.1
        recentActivitySummary = Self.recentActivitySummary(for: tips, now: now, calendar: calendar)
        hasCurrentMonthTips = !currentMonthTips.isEmpty
    }

    private static func mostCommonSplitCount(in tips: [SavedTip]) -> Int {
        let counts = tips.reduce(into: [Int: Int]()) { result, tip in
            result[Int(tip.numberOfPeople), default: 0] += 1
        }

        return counts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            }

            return lhs.value > rhs.value
        }
        .first?
        .key ?? 0
    }

    private static func mostCommonTipPercentage(in tips: [SavedTip]) -> Double {
        let counts = tips.reduce(into: [Double: Int]()) { result, tip in
            result[tip.tipPercentage, default: 0] += 1
        }

        return counts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            }

            return lhs.value > rhs.value
        }
        .first?
        .key ?? 0
    }

    private static func recentActivitySummary(for tips: [SavedTip], now: Date, calendar: Calendar) -> String {
        let recentDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let recentCount = tips.filter { tip in
            guard let date = tip.date else {
                return false
            }

            return date >= recentDate && date <= now
        }.count

        if recentCount == 0 {
            return String(localized: "No saves in the last 7 days")
        }

        return String(localized: "\(recentCount) saved in the last 7 days")
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
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SavedPreview") ?? .standard))
}

#Preview("Empty Saved Tips") {
    SavedView()
        .environmentObject(DataManager.emptyPreview)
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SavedEmptyPreview") ?? .standard))
}

#Preview("Many Saved Tips") {
    SavedView()
        .environmentObject(DataManager.manyItemsPreview)
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SavedManyPreview") ?? .standard))
}

#Preview("Saved Tips Error") {
    SavedView()
        .environmentObject(DataManager.errorPreview)
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "SavedErrorPreview") ?? .standard))
}
