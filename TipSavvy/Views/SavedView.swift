//
//  HistoryView.swift
//  TipSavvy
//
//  Created by Kabir Dhillon on 6/8/23.
//

import Accessibility
import Charts
import SwiftUI

/// A view that displays a list of saved tip calculations, or a message indicating that there are no saved tip calculations.
struct SavedView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settings: TipSavvySettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onUseAgain: (SavedTip) -> Void
    let onStartCalculation: () -> Void

    @State private var searchText = ""
    @State private var renameText = ""
    @State private var tipBeingRenamed: SavedTip?
    @State private var recentlyDeleted: SavedTipRecord?
    @State private var selectedTip: SavedTip?
    @State private var showingSavedInsightsDetails = false
    @State private var showingRenameAlert = false
    @State private var dataErrorMessage: String?
    @AppStorage(SavedTipListPreferenceKey.sortMode) private var sortModeRawValue = SavedTipSortMode.newest.rawValue
    @AppStorage(SavedTipListPreferenceKey.filterMode) private var filterModeRawValue = SavedTipFilterMode.all.rawValue

    private let dateFormatMMDDYYYY = Date.FormatStyle.dateTime.month().day().year()
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"

    init(onUseAgain: @escaping (SavedTip) -> Void = { _ in },
         onStartCalculation: @escaping () -> Void = {}) {
        self.onUseAgain = onUseAgain
        self.onStartCalculation = onStartCalculation
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
            let matchesSearch = trimmedSearch.isEmpty
                || (tip.name ?? "").localizedCaseInsensitiveContains(trimmedSearch)
                || (tip.note ?? "").localizedCaseInsensitiveContains(trimmedSearch)
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
                    savedList
                }
            }
            .navigationTitle(String(localized: "Saved Tips"))
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: String(localized: "Search Names and Notes"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    listOptionsMenu
                }
            }
            .toastOverlay(isPresented: dataErrorMessage != nil || recentlyDeleted != nil) {
                if let dataErrorMessage {
                    TipSavvyErrorBanner(message: dataErrorMessage) {
                        self.dataErrorMessage = nil
                        dataManager.lastError = nil
                    }
                } else if let recentlyDeleted {
                    TipSavvyUndoBanner(message: String(localized: "Deleted \(recentlyDeleted.name)")) {
                        undoDelete(recentlyDeleted)
                    }
                }
            }
            .task(id: recentlyDeleted) {
                guard let record = recentlyDeleted else {
                    return
                }
                try? await Task.sleep(for: .seconds(8))
                if recentlyDeleted == record {
                    recentlyDeleted = nil
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
        .onChange(of: dataManager.lastError) { error in
            dataErrorMessage = error?.localizedDescription
        }
    }

    private var isShowingDefaultListOptions: Bool {
        sortMode == .newest && filterMode == .all
    }

    /// Sort and filter in one menu, as Mail and Files do. The icon fills when the list
    /// is not in its default order and scope, so the state stays visible.
    private var listOptionsMenu: some View {
        Menu {
            Section(String(localized: "Sort By")) {
                Picker(String(localized: "Sort Saved Tips"), selection: sortModeBinding) {
                    ForEach(SavedTipSortMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
            }
            Section(String(localized: "Show")) {
                Picker(String(localized: "Filter Saved Tips"), selection: filterModeBinding) {
                    ForEach(SavedTipFilterMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
            }
        } label: {
            Image(systemName: isShowingDefaultListOptions ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .accessibilityLabel(String(localized: "Sort and Filter"))
        }
        .accessibilityValue(isShowingDefaultListOptions ? "" : "\(sortMode.title), \(filterMode.title)")
        .accessibilityIdentifier("Saved Tips Options")
    }

    /// This month's figure with a six-month sparkline beside it, so the number has context.
    private var savedInsightsButton: some View {
        Button {
            showingSavedInsightsDetails = true
        } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Spent This Month"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondary)
                    Text(savedInsights.currentMonthTotalWithTip, format: .currency(code: localCurrency))
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundStyle(settings.selectedTheme.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(String(localized: "\(savedInsights.currentMonthTipTotal.formatted(.currency(code: localCurrency))) in tips"))
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .monospacedDigit()
                }

                Spacer(minLength: 8)

                SpendingSparkline(entries: savedInsights.monthlySpending, accentColor: settings.selectedTheme.accentColor)
                    .frame(width: 84, height: 40)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Spent This Month"))
        .accessibilityValue(String(localized: "\(savedInsights.currentMonthTotalWithTip.formatted(.currency(code: localCurrency))), \(savedInsights.currentMonthTipTotal.formatted(.currency(code: localCurrency))) in tips"))
        .accessibilityHint(String(localized: "Shows detailed saved insights."))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("Saved Insights")
    }

    private var savedList: some View {
        List {
            Section {
                savedInsightsButton
            }

            Section {
                if filteredTips.isEmpty {
                    noMatchesRow
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredTips) { tip in
                        savedTipRow(for: tip)
                    }
                }
            } footer: {
                if hasActiveFiltering && !filteredTips.isEmpty {
                    Text(filteredTips.count == 1 ? String(localized: "1 matching tip") : String(localized: "\(filteredTips.count) matching tips"))
                        .accessibilityIdentifier("Visible Saved Tips")
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: filteredTips.map(\.objectID))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: searchText)
    }

    private func savedTipRow(for tip: SavedTip) -> some View {
        Button {
            selectedTip = tip
        } label: {
            savedTipCard(for: tip)
        }
        .contextMenu {
            Button {
                useAgain(tip)
            } label: {
                Label(String(localized: "Use Again"), systemImage: "arrow.counterclockwise")
            }

            Button {
                startRename(for: tip)
            } label: {
                Label(String(localized: "Rename"), systemImage: "pencil")
            }

            Button(role: .destructive) {
                deleteTip(tip)
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                useAgain(tip)
            } label: {
                Label(String(localized: "Use Again"), systemImage: "arrow.counterclockwise")
            }
            .tint(.teal)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteTip(tip)
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
            .tint(.red)

            Button {
                startRename(for: tip)
            } label: {
                Label(String(localized: "Rename"), systemImage: "pencil")
            }
            .tint(.blue)
        }
        .accessibilityAction(named: String(localized: "Use Again")) { useAgain(tip) }
        .accessibilityAction(named: String(localized: "Rename")) { startRename(for: tip) }
        .accessibilityAction(named: String(localized: "Delete")) { deleteTip(tip) }
    }

    /// Two lines: what and how much, then when, how and per person.
    private func savedTipCard(for tip: SavedTip) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(tip.name ?? String(localized: "Untitled Tip"))
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                Spacer(minLength: 12)
                Text(tip.totalAmountWithTip, format: .currency(code: localCurrency))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.primary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(rowDetail(for: tip))
                    .lineLimit(2)
                Spacer(minLength: 12)
                if tip.numberOfPeople > 1 {
                    Text(String(localized: "\(tip.totalPerPerson.formatted(.currency(code: localCurrency))) each"))
                        .monospacedDigit()
                }
            }
            .font(.subheadline)
            .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tip.accessibilitySummary(currencyCode: localCurrency, dateFormat: dateFormatMMDDYYYY))
        .accessibilityHint(String(localized: "Opens saved tip details"))
    }

    private func rowDetail(for tip: SavedTip) -> String {
        var parts: [String] = []
        if let date = tip.date {
            let sameYear = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            parts.append(date.formatted(sameYear ? .dateTime.month(.abbreviated).day() : .dateTime.month(.abbreviated).day().year()))
        }
        parts.append("\(Int(tip.tipPercentage))%")
        parts.append(tip.numberOfPeople == 1 ? String(localized: "1 person") : String(localized: "\(Int(tip.numberOfPeople)) people"))
        return parts.joined(separator: " · ")
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
                    } else if dataManager.savedTips.isEmpty {
                        startCalculationButton
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .fontWeight(.medium)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text(title)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    if hasActiveFiltering {
                        clearFiltersButton
                    } else if dataManager.savedTips.isEmpty {
                        startCalculationButton
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .accessibilityLabel(title)
        .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.98)))
    }

    /// Shown inside the list when search or filter hides every tip. A plain stack rather than
    /// `ContentUnavailableView`, which stretches its action button inside a list cell.
    private var noMatchesRow: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(String(localized: "No Matching Tips"))
                .font(.title3.weight(.semibold))
            Text(emptyMatchingDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if hasActiveFiltering {
                clearFiltersButton
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
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
            Text(String(localized: "Clear Filters"))
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("Clear Saved Tip Filters")
    }

    private var startCalculationButton: some View {
        Button {
            onStartCalculation()
        } label: {
            Label(String(localized: "Start a Calculation"), systemImage: "percent")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("Start a Calculation")
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

    /// Deletes immediately and offers an undo, rather than asking for confirmation first.
    private func deleteTip(_ tip: SavedTip) {
        let record = SavedTipRecord(tip)
        var result: Result<Void, DataManagerError> = .success(())
        performAnimated(.easeInOut(duration: 0.22)) {
            result = dataManager.deleteTip(tip)
        }
        if case .success = result {
            recentlyDeleted = record
            HapticFeedbackPerformer.warning(isEnabled: settings.hapticsEnabled)
        }
    }

    private func undoDelete(_ record: SavedTipRecord) {
        performAnimated(.easeInOut(duration: 0.22)) {
            _ = dataManager.restoreTip(record)
        }
        recentlyDeleted = nil
        HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
    }

    private func useAgain(_ tip: SavedTip) {
        onUseAgain(tip)
        HapticFeedbackPerformer.success(isEnabled: settings.hapticsEnabled)
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
    @EnvironmentObject var settings: TipSavvySettings

    let insights: SavedTipInsights
    let currencyCode: String

    @ScaledMetric(relativeTo: .body) private var chartHeight: CGFloat = 180

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    spendingChartSection
                    allTimeSection
                    highlightsSection
                }
                .padding(18)
                .padding(.bottom, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Saved Insights"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SheetCloseButton {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("Saved Insights Detail")
    }

    /// Bars carry their own value labels, so the y-axis and gridlines are dropped.
    /// The current month is drawn at full strength; earlier months recede. The average
    /// is labelled on its own rule rather than in a legend.
    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(String(localized: "Spending by Month"))

            if insights.monthlySpending.allSatisfy({ $0.totalSpent == 0 }) {
                Text(String(localized: "Save tips to see your spending history."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let accentColor = settings.selectedTheme.accentColor
                let currentMonth = insights.monthlySpending.last?.month
                let average = insights.averageMonthlySpending
                let peak = insights.monthlySpending.map(\.totalSpent).max() ?? 0

                Chart {
                    ForEach(insights.monthlySpending) { entry in
                        BarMark(
                            x: .value(String(localized: "Month"), entry.month, unit: .month),
                            y: .value(String(localized: "Spent"), entry.totalSpent),
                            width: .ratio(0.6)
                        )
                        .foregroundStyle(entry.month == currentMonth ? accentColor : accentColor.opacity(0.35))
                        .cornerRadius(2)
                        .annotation(position: .top, spacing: 4) {
                            if entry.totalSpent > 0 {
                                Text(entry.totalSpent, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                                    .font(.caption2.weight(entry.month == currentMonth ? .bold : .regular).monospacedDigit())
                                    .foregroundStyle(entry.month == currentMonth ? Color.primary : Color.secondary)
                            }
                        }
                    }

                    if average > 0 {
                        RuleMark(y: .value(String(localized: "Average"), average))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .annotation(position: .bottom, alignment: .leading, spacing: 2) {
                                Text(String(localized: "avg \(average.formatted(.currency(code: currencyCode).precision(.fractionLength(0))))"))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .chartYScale(domain: 0...(peak * 1.18))
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: chartHeight)
                .accessibilityLabel(String(localized: "Spending by month"))
                .accessibilityChartDescriptor(MonthlySpendingChartDescriptor(entries: insights.monthlySpending, currencyCode: currencyCode))
            }

            Text(thisMonthSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("Saved Insights This Month")
        }
        .padding(18)
        .contentCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Saved Insights Spending Chart")
    }

    private var thisMonthSummary: String {
        guard insights.hasCurrentMonthTips else {
            return String(localized: "No saved tips from this month yet.")
        }
        let count = insights.currentMonthSavedTipCount
        let spent = insights.currentMonthTotalWithTip.formatted(.currency(code: currencyCode))
        let tips = insights.currentMonthTipTotal.formatted(.currency(code: currencyCode))
        return count == 1
            ? String(localized: "This month: \(spent) across 1 saved tip, \(tips) of it in tips.")
            : String(localized: "This month: \(spent) across \(count) saved tips, \(tips) of it in tips.")
    }

    /// Totals and averages side by side, so the pairs (spent vs. tips, bill vs. tip) compare directly.
    private var allTimeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(String(localized: "All Time"))

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    statCell(String(localized: "Total Spent"), insights.allTimeTotalWithTip.formatted(.currency(code: currencyCode)))
                    statCell(String(localized: "Total Tips"), insights.allTimeTipTotal.formatted(.currency(code: currencyCode)))
                }
                GridRow {
                    statCell(String(localized: "Average Bill"), insights.averageBillAmount.formatted(.currency(code: currencyCode)))
                    statCell(String(localized: "Average Tip"), percentageText(insights.averageTipPercentage))
                }
                GridRow {
                    statCell(String(localized: "Saved Tips"), "\(insights.allTimeSavedTipCount)")
                    if insights.savedTipsWithTaxCount > 0 {
                        statCell(String(localized: "Average Tax"), insights.averageTaxAmount.formatted(.currency(code: currencyCode)))
                    } else {
                        statCell(String(localized: "Average Per Person"), insights.averagePerPersonTotal.formatted(.currency(code: currencyCode)))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .contentCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Saved Insights All Time")
    }

    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    /// Extremes and habits in one list. Whitespace separates rows; names ride under their figure.
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(String(localized: "Highlights"))
            highlightRow(String(localized: "Largest Bill"), insights.largestSavedBill.formatted(.currency(code: currencyCode)), detail: insights.largestSavedBillName)
            highlightRow(String(localized: "Highest Tip"), percentageText(insights.highestTipPercentage), detail: insights.highestTipName)
            highlightRow(String(localized: "Common Tip"), percentageText(insights.mostCommonTipPercentage))
            highlightRow(String(localized: "Common Split"), insights.mostCommonSplitCount == 1 ? String(localized: "1 person") : String(localized: "\(insights.mostCommonSplitCount) people"))
            if insights.savedTipsWithTaxCount > 0 {
                highlightRow(String(localized: "Saved With Tax"), "\(insights.savedTipsWithTaxCount)")
            }
            highlightRow(String(localized: "Recent Activity"), insights.recentActivitySummary)
        }
        .padding(18)
        .contentCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Saved Insights Highlights")
    }

    private func highlightRow(_ title: String, _ value: String, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            InfoRow(title: title, value: value)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    private func percentageText(_ percentage: Double) -> String {
        String(format: "%.0f%%", percentage)
    }
}

/// A word-sized bar chart: six months, no axes or labels, the current month emphasized.
struct SpendingSparkline: View {
    let entries: [MonthlySpending]
    let accentColor: Color

    var body: some View {
        let currentMonth = entries.last?.month
        Chart {
            ForEach(entries) { entry in
                BarMark(
                    x: .value(String(localized: "Month"), entry.month, unit: .month),
                    y: .value(String(localized: "Spent"), entry.totalSpent),
                    width: .ratio(0.62)
                )
                .foregroundStyle(entry.month == currentMonth ? accentColor : accentColor.opacity(0.3))
                .cornerRadius(1.5)
            }
            // A baseline keeps empty months visible as slots rather than gaps.
            RuleMark(y: .value(String(localized: "Spent"), 0))
                .foregroundStyle(Color.secondary.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .accessibilityHidden(true)
    }
}

/// Exposes the monthly bars to VoiceOver's chart navigation and Audio Graphs.
struct MonthlySpendingChartDescriptor: AXChartDescriptorRepresentable {
    let entries: [MonthlySpending]
    let currencyCode: String

    func makeChartDescriptor() -> AXChartDescriptor {
        let monthFormat = Date.FormatStyle.dateTime.month(.wide).year()
        let maxSpent = max(entries.map(\.totalSpent).max() ?? 0, 1)

        let xAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: "Month"),
            categoryOrder: entries.map { $0.month.formatted(monthFormat) }
        )
        let yAxis = AXNumericDataAxisDescriptor(
            title: String(localized: "Spent"),
            range: 0...maxSpent,
            gridlinePositions: []
        ) { [currencyCode] value in
            value.formatted(.currency(code: currencyCode))
        }
        let series = AXDataSeriesDescriptor(
            name: String(localized: "Spending"),
            isContinuous: false,
            dataPoints: entries.map { entry in
                AXDataPoint(x: entry.month.formatted(monthFormat), y: entry.totalSpent)
            }
        )

        return AXChartDescriptor(
            title: String(localized: "Spending by month"),
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

struct MonthlySpending: Identifiable, Equatable {
    let id = UUID()
    let month: Date
    let totalSpent: Double
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
    let monthlySpending: [MonthlySpending]

    /// Mean across the months shown in the chart, including months with no spending.
    var averageMonthlySpending: Double {
        guard !monthlySpending.isEmpty else {
            return 0
        }
        return monthlySpending.reduce(0) { $0 + $1.totalSpent } / Double(monthlySpending.count)
    }

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
        monthlySpending = (0..<6).reversed().compactMap { offset -> MonthlySpending? in
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: now),
                  let interval = calendar.dateInterval(of: .month, for: monthStart) else { return nil }
            let monthTips = tips.filter { tip in
                guard let date = tip.date else { return false }
                return interval.contains(date)
            }
            return MonthlySpending(month: interval.start, totalSpent: monthTips.reduce(0) { $0 + $1.totalAmountWithTip })
        }
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
