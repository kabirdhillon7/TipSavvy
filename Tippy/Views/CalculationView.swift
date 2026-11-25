//
//  ContentView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI
import UIKit

/// A view that calculates a tip calculation.
///
/// Layout: a compact results readout first, then the inputs in the order people think
/// about them (bill, people, tip), then Save. Clear and Copy live in the toolbar.
struct CalculationView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settings: TipSavvySettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @StateObject private var viewModel: CalculationViewModel

    @State private var showingSaveSheet = false
    @State private var successMessage: String?
    @State private var dataErrorMessage: String?
    @State private var showingTaxDetails = false
    @State private var isDraggingTipSlider = false
    @State private var totalsPanelIsOffscreen = false
    @FocusState var keyboardFocusField: TipSavvyKeyboardField?

    private let localCurrency = Locale.current.currency?.identifier ?? "USD"

    @MainActor
    init(viewModel: CalculationViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? CalculationViewModel())
    }

    private var accentColor: Color { settings.selectedTheme.accentColor }
    private var isSplit: Bool { viewModel.numberOfPeople > 1 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    totalsReadout
                        .modifier(ScrollVisibilityModifier { isVisible in
                            if isVisible == totalsPanelIsOffscreen {
                                performAnimated(.easeInOut(duration: 0.2)) {
                                    totalsPanelIsOffscreen = !isVisible
                                }
                            }
                        })
                    billAmountCard
                    splitCard
                    tipCard
                    saveButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            // An overlay rather than a safe-area inset, so content doesn't jump under the finger.
            .overlay(alignment: .top) {
                if totalsPanelIsOffscreen {
                    pinnedTotalsBar
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TipSavvy")
            .toastOverlay(isPresented: dataErrorMessage != nil || successMessage != nil || viewModel.undoOffer != nil) {
                if let dataErrorMessage {
                    TipSavvyErrorBanner(message: dataErrorMessage) {
                        self.dataErrorMessage = nil
                        dataManager.lastError = nil
                    }
                } else if let undoOffer = viewModel.undoOffer {
                    TipSavvyUndoBanner(message: undoOffer.message) {
                        performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                            viewModel.undo()
                        }
                        HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                    }
                } else if let successMessage {
                    TipSavvySuccessBanner(message: successMessage)
                }
            }
            .task(id: viewModel.undoOffer?.id) {
                guard let offerID = viewModel.undoOffer?.id else {
                    return
                }
                try? await Task.sleep(for: .seconds(8))
                if viewModel.undoOffer?.id == offerID {
                    viewModel.undoOffer = nil
                }
            }
            .task(id: successMessage) {
                guard let message = successMessage else {
                    return
                }
                try? await Task.sleep(for: .seconds(2.5))
                if successMessage == message {
                    successMessage = nil
                }
            }
            .sheet(isPresented: $showingSaveSheet) {
                saveTipSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: viewModel.numberOfPeople, perform: { _ in
                viewModel.persistSmartDefaults()
            })
            .onChange(of: dataManager.lastError) { error in
                dataErrorMessage = error?.localizedDescription
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.numberOfPeople)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.totalAmountWithTip)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.totalPerPerson)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showingTaxDetails)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: successMessage)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    clearButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    copyMenu
                }

                ToolbarItem(placement: .keyboard) {
                    Spacer()
                }

                ToolbarItem(placement: .keyboard) {
                    Button {
                        keyboardFocusField = nil
                    } label: {
                        Text("Done")
                            .accessibilityLabel(String(localized: "Done"))
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }

    // MARK: - Results

    /// The answer, stated once: the hero figure, then the arithmetic that produced it.
    private var totalsReadout: some View {
        VStack(alignment: .leading, spacing: 14) {
            Group {
                if isSplit {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 12) {
                            perPersonMetric
                            totalMetric(prominence: .regular)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            perPersonMetric
                            totalMetric(prominence: .regular)
                        }
                    }
                } else {
                    // With one person, per-person equals the total; show it once.
                    totalMetric(prominence: .primary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Totals"))
            .accessibilityValue(viewModel.accessibilityTotalsSummary(currencyCode: localCurrency))
            .contextMenu { copyMenuItems }

            VStack(spacing: 8) {
                InfoRow(title: String(localized: "Subtotal"), value: viewModel.subtotalAmount.formatted(.currency(code: localCurrency)))
                if viewModel.hasTax {
                    InfoRow(title: String(localized: "Tax"), value: viewModel.sanitizedTaxAmount.formatted(.currency(code: localCurrency)))
                }
                InfoRow(title: tipBreakdownTitle, value: viewModel.tipAmount.formatted(.currency(code: localCurrency)))
            }

            if let roundingExplanation {
                Text(roundingExplanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("Rounding Explanation")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .contentCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Bill Totals"))
        .accessibilityIdentifier("Bill Totals Summary")
    }

    private var perPersonMetric: some View {
        MetricCard(title: String(localized: "Per Person"),
                   value: viewModel.totalPerPerson.formatted(.currency(code: localCurrency)),
                   prominence: .primary,
                   accentColor: accentColor)
    }

    private func totalMetric(prominence: MetricCard.Prominence) -> some View {
        MetricCard(title: String(localized: "Total With Tip"),
                   value: viewModel.totalAmountWithTip.formatted(.currency(code: localCurrency)),
                   prominence: prominence,
                   accentColor: accentColor)
    }

    private var percentText: String {
        String(format: "%.0f%%", viewModel.tipPercentage)
    }

    private var tipBreakdownTitle: String {
        if viewModel.hasTax && viewModel.tipTaxBasis == .subtotalAndTax {
            return String(localized: "Tip \(percentText) of Subtotal + Tax")
        }
        return String(localized: "Tip \(percentText)")
    }

    private var roundingExplanation: String? {
        guard viewModel.hasValidCalculation else {
            return nil
        }
        switch viewModel.roundingMode {
        case .none:
            return nil
        case .roundTotalUp:
            return String(localized: "Rounded total from \(viewModel.unroundedTotalForDisplay.formatted(.currency(code: localCurrency))) to \(viewModel.totalAmountWithTip.formatted(.currency(code: localCurrency))).")
        case .roundPerPersonUp:
            return String(localized: "Rounded each person from \(viewModel.unroundedPerPersonForDisplay.formatted(.currency(code: localCurrency))) to \(viewModel.totalPerPerson.formatted(.currency(code: localCurrency))).")
        }
    }

    /// A compact readout that floats over the inputs once the results card scrolls away.
    private var pinnedTotalsBar: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 0) {
                Text(isSplit ? String(localized: "Per Person") : String(localized: "Total"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(isSplit ? viewModel.totalPerPerson : viewModel.totalAmountWithTip, format: .currency(code: localCurrency))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(accentColor)
                    .animatedTextChange(value: isSplit ? viewModel.totalPerPerson : viewModel.totalAmountWithTip)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 0) {
                Text(isSplit ? String(localized: "Total") + " · " + percentText : String(localized: "Tip") + " · " + percentText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(isSplit ? viewModel.totalAmountWithTip : viewModel.tipAmount, format: .currency(code: localCurrency))
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .animatedTextChange(value: isSplit ? viewModel.totalAmountWithTip : viewModel.tipAmount)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .floatingGlass(in: Capsule(style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Totals"))
        .accessibilityValue(viewModel.accessibilityTotalsSummary(currencyCode: localCurrency))
        .accessibilityIdentifier("Pinned Totals")
    }

    // MARK: - Bill

    private var billAmountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeader(String(localized: "Bill"))

            HStack(alignment: .center, spacing: 12) {
                TextField(String(localized: "Enter Bill Amount"),
                          value: $viewModel.billAmount,
                          format: .currency(code: localCurrency))
                    .font(.largeTitle.weight(.bold).monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($keyboardFocusField, equals: .billAmount)
                    .textFieldStyle(.plain)
                    .accessibilityLabel(String(localized: "Enter Bill Amount"))
            }

            if let message = viewModel.billValidationMessage, viewModel.billAmount != nil || keyboardFocusField != .billAmount {
                let isError = viewModel.billAmount != nil
                Label(message, systemImage: isError ? "exclamationmark.circle.fill" : "info.circle")
                    .font(.footnote)
                    .foregroundStyle(isError ? Color.red : Color.secondary)
                    .accessibilityIdentifier("Bill Validation Message")
            }

            Divider()

            taxDetailsSection
        }
        .padding(18)
        .contentCard(highlight: keyboardFocusField == .billAmount ? accentColor : nil)
    }

    /// The collapsed row states what tax is doing, so nothing is hidden behind the disclosure.
    private var taxSummary: String {
        if viewModel.hasTax {
            return String(localized: "Tax \(viewModel.sanitizedTaxAmount.formatted(.currency(code: localCurrency))) · tip on \(viewModel.tipTaxBasis.title)")
        }
        return String(localized: "Add Tax")
    }

    private var taxDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showingTaxDetails.toggle()
                HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
            } label: {
                HStack(spacing: 10) {
                    Text(showingTaxDetails ? String(localized: "Tax") : taxSummary)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(viewModel.hasTax || showingTaxDetails ? Color.primary : accentColor)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showingTaxDetails ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Tax Details"))
            .accessibilityValue(viewModel.hasTax ? taxSummary : "")
            .accessibilityIdentifier("Tax Details Toggle")

            if showingTaxDetails {
                VStack(alignment: .leading, spacing: 10) {
                    TextField(String(localized: "Optional Tax Amount"),
                              value: $viewModel.taxAmount,
                              format: .currency(code: localCurrency))
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .keyboardType(.decimalPad)
                        .focused($keyboardFocusField, equals: .taxAmount)
                        .textFieldStyle(.plain)
                        .accessibilityLabel(String(localized: "Optional Tax Amount"))
                        .accessibilityIdentifier("Optional Tax Amount")

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "Tip On"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker(String(localized: "Tip Basis"), selection: $viewModel.tipTaxBasis) {
                            ForEach(TipTaxBasis.allCases) { basis in
                                Text(basis.title).tag(basis)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.tipTaxBasis) { _ in
                            viewModel.persistSmartDefaults()
                        }
                        .accessibilityIdentifier("Tip Tax Basis")
                    }

                    if let message = viewModel.taxValidationMessage {
                        Label(message, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("Tax Validation Message")
                    }
                }
                .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - People

    private var splitCard: some View {
        HStack {
            peopleButton(systemImage: "minus", label: String(localized: "Decrease People"), isDisabled: viewModel.numberOfPeople <= 1) {
                viewModel.numberOfPeople = max(1, viewModel.numberOfPeople - 1)
            }

            Spacer(minLength: 12)
            peopleCount
            Spacer(minLength: 12)

            peopleButton(systemImage: "plus", label: String(localized: "Increase People"), isDisabled: viewModel.numberOfPeople >= 99) {
                viewModel.numberOfPeople = min(99, viewModel.numberOfPeople + 1)
            }
        }
        .padding(18)
        .contentCard()
        .accessibilityElement(children: .contain)
    }

    private var peopleCount: some View {
        VStack(spacing: 0) {
            Text(viewModel.numberOfPeople, format: .number)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .animatedTextChange(value: viewModel.numberOfPeople)
            Text(viewModel.numberOfPeople == 1 ? String(localized: "Person") : String(localized: "People"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Number of People"))
        .accessibilityValue("\(viewModel.numberOfPeople)")
        .accessibilityIdentifier("Number of People")
    }

    private func peopleButton(systemImage: String, label: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            performAnimated(.spring(response: 0.26, dampingFraction: 0.82)) {
                action()
            }
            HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
        } label: {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .frame(width: 36, height: 36)
        }
        .glassCircleButtonStyle()
        .disabled(isDisabled)
        .accessibilityLabel(label)
    }

    // MARK: - Tip

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                cardHeader(String(localized: "Tip"))
                Spacer(minLength: 12)
                servicePicker
            }

            tipComparisonSection

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(localized: "Custom"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    customTipText
                }
                tipSlider
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Rounding"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Picker(String(localized: "Rounding"), selection: $viewModel.roundingMode) {
                    ForEach(RoundingMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.roundingMode) { _ in
                    HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                    viewModel.persistSmartDefaults()
                }
                .accessibilityIdentifier("Rounding Mode")
            }
        }
        .padding(18)
        .contentCard()
    }

    /// Where the tip is for. Picking a service swaps in that service's typical presets.
    private var servicePicker: some View {
        Picker(selection: $viewModel.serviceContext) {
            ForEach(TipServiceContext.allCases) { context in
                Label(context.label, systemImage: context.systemImage).tag(context)
            }
        } label: {
            Text(String(localized: "Service"))
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .fixedSize()
        .onChange(of: viewModel.serviceContext) { _ in
            viewModel.persistSmartDefaults()
            HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
        }
        .accessibilityLabel(String(localized: "Tip Service Context"))
        .accessibilityValue(viewModel.serviceContext.label)
        .accessibilityHint(viewModel.serviceContext.helperText)
        .accessibilityIdentifier("Tip Service Context")
    }

    /// One row per preset, each showing the same figures so they can be compared at a glance.
    /// The row count never changes while the slider moves, so the slider stays under the finger.
    private var tipComparisonSection: some View {
        let presets = viewModel.serviceContext.suggestedPresets
        let comparisons = viewModel.tipComparisons(for: presets)

        return VStack(alignment: .leading, spacing: 2) {
            ForEach(presets, id: \.self) { percentage in
                tipComparisonRow(percentage: percentage,
                                 comparison: comparisons.first { $0.percentage == percentage })
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Tip Comparison")
    }

    private func tipComparisonRow(percentage: Double, comparison: TipComparison?) -> some View {
        let isSelected = viewModel.tipPercentage == percentage
        let rowPercentText = String(format: "%.0f%%", percentage)

        return Button {
            performAnimated(.spring(response: 0.28, dampingFraction: 0.78)) {
                viewModel.tipPercentage = percentage
                viewModel.persistSmartDefaults()
            }
            HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accentColor)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(rowPercentText)
                        .font(.body.weight(isSelected ? .bold : .regular).monospacedDigit())
                    if let comparison {
                        Text(String(localized: "Tip \(comparison.tipAmount.formatted(.currency(code: localCurrency)))"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 8)

                if let comparison {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(comparison.totalAmountWithTip, format: .currency(code: localCurrency))
                            .font(.body.weight(isSelected ? .bold : .regular))
                            .monospacedDigit()
                        if isSplit {
                            Text(String(localized: "\(comparison.totalPerPerson.formatted(.currency(code: localCurrency))) each"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: GlassRadius.inner, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(colorSchemeContrast == .increased ? 0.24 : 0.12) : Color.clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rowPercentText)
        .accessibilityValue(tipRowAccessibilityValue(comparison: comparison))
        .accessibilityHint(String(localized: "Applies this tip percentage"))
        .modifier(SelectedAccessibilityTraitModifier(isSelected: isSelected))
    }

    /// Selection is conveyed by the `.isSelected` trait, so the value carries only the amounts.
    private func tipRowAccessibilityValue(comparison: TipComparison?) -> String {
        guard let comparison else {
            return ""
        }
        return String(localized: "Total \(comparison.totalAmountWithTip.formatted(.currency(code: localCurrency))), per person \(comparison.totalPerPerson.formatted(.currency(code: localCurrency)))")
    }

    /// When the slider sets a value no row offers, the caption carries the tip amount instead.
    private var customTipText: some View {
        let isCustom = !viewModel.serviceContext.suggestedPresets.contains(viewModel.tipPercentage)
        let text = isCustom
            ? percentText + " · " + viewModel.tipAmount.formatted(.currency(code: localCurrency))
            : percentText
        return Text(text)
            .font(.headline.weight(isCustom ? .bold : .regular).monospacedDigit())
            .foregroundStyle(isCustom ? accentColor : Color.secondary)
            .lineLimit(1)
            .animatedTextChange(value: text)
    }

    private var tipSlider: some View {
        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1) { isEditing in
            isDraggingTipSlider = isEditing
        }
            .tint(accentColor)
            .onChange(of: viewModel.tipPercentage, perform: { _ in
                // Rows fire their own haptic; only tick here while the slider is being dragged.
                if isDraggingTipSlider {
                    HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                }
                viewModel.persistSmartDefaults()
            })
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.tipPercentage)
            .accessibilityLabel(String(localized: "Tip Percentage Selection"))
            .accessibilityValue("\(viewModel.tipPercentage, specifier: "%.0f")%")
            .accessibilityHint(String(localized: "Selects the Tip Percentage"))
    }

    // MARK: - Actions

    private var saveButton: some View {
        Button {
            showingSaveSheet = true
        } label: {
            Label(String(localized: "Save"), systemImage: "tray.and.arrow.down")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .glassProminentButtonStyle()
        .controlSize(.large)
        .tint(accentColor)
        .disabled(!viewModel.hasValidCalculation)
        .accessibilityLabel(String(localized: "Save Tip Calculation"))
        .accessibilityHint(viewModel.hasValidCalculation ? String(localized: "Saves the Tip Calculation") : String(localized: "Enter a bill amount greater than zero before saving"))
    }

    /// Clearing is undoable, so it is an ordinary toolbar action rather than a red button.
    private var clearButton: some View {
        Button {
            let previous = viewModel.snapshot()
            let hadInput = viewModel.hasUserInput
            performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                viewModel.resetValues()
                viewModel.applySettingsDefaults(defaultTipPercentage: settings.defaultTipPercentage,
                                                defaultNumberOfPeople: settings.defaultNumberOfPeople)
            }
            if hadInput {
                viewModel.undoOffer = .init(message: String(localized: "Calculation cleared"), snapshot: previous)
            }
            HapticFeedbackPerformer.warning(isEnabled: settings.hapticsEnabled)
        } label: {
            Label(String(localized: "Clear"), systemImage: "arrow.counterclockwise")
        }
        .disabled(!viewModel.hasUserInput)
        .accessibilityLabel(String(localized: "Clear Calculation"))
        .accessibilityIdentifier("Reset")
    }

    private var copyMenu: some View {
        Menu {
            copyMenuItems
        } label: {
            Label(String(localized: "Copy"), systemImage: "doc.on.doc")
        }
        .disabled(!viewModel.hasValidCalculation)
        .accessibilityLabel(String(localized: "Copy Amount"))
        .accessibilityIdentifier("Copy Menu")
    }

    @ViewBuilder
    private var copyMenuItems: some View {
        if isSplit {
            Button {
                copy(viewModel.totalPerPerson, confirmation: String(localized: "Per person amount copied"))
            } label: {
                Label(String(localized: "Copy Per Person"), systemImage: "person")
            }
        }
        Button {
            copy(viewModel.totalAmountWithTip, confirmation: String(localized: "Total copied"))
        } label: {
            Label(String(localized: "Copy Total"), systemImage: "sum")
        }
    }

    private func copy(_ amount: Double, confirmation: String) {
        UIPasteboard.general.string = amount.formatted(.currency(code: localCurrency))
        HapticFeedbackPerformer.lightImpact(isEnabled: settings.hapticsEnabled)
        successMessage = confirmation
    }

    private func cardHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    private var saveTipSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "Enter Name"), text: $viewModel.tipItemName)
                        .autocorrectionDisabled()
                        .accessibilityLabel(String(localized: "Enter Tip Calculation Name"))
                        .accessibilityIdentifier("Enter Tip Calculation Name")

                    TextField(String(localized: "Receipt Note"), text: $viewModel.receiptNote, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .accessibilityLabel(String(localized: "Receipt Note"))
                        .accessibilityIdentifier("Receipt Note")
                } footer: {
                    Text(String(localized: "Notes stay on this device with the saved calculation."))
                }

                Section {
                    InfoRow(title: String(localized: "Total With Tip"), value: viewModel.totalAmountWithTip.formatted(.currency(code: localCurrency)))
                    if isSplit {
                        InfoRow(title: String(localized: "Per Person"), value: viewModel.totalPerPerson.formatted(.currency(code: localCurrency)))
                    }
                }
            }
            .navigationTitle(String(localized: "Save Tip"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        viewModel.tipItemName = ""
                        viewModel.receiptNote = ""
                        showingSaveSheet = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveTipInfo()
                    }
                    .disabled(!viewModel.canSaveTip)
                }
            }
        }
        .onAppear {
            if viewModel.tipItemName.isEmpty {
                viewModel.tipItemName = viewModel.suggestedTipName
            }
        }
    }

    private func performAnimated(_ animation: Animation, _ updates: () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }

    /// Saves the tip information to the data manager.
    func saveTipInfo() {
        guard let billAmount = viewModel.billAmount, viewModel.canSaveTip else {
            return
        }

        let result = dataManager.saveTip(name: viewModel.tipItemName.trimmingCharacters(in: .whitespacesAndNewlines),
                                         note: viewModel.receiptNote,
                                         billAmount: billAmount,
                                         tipPercentage: viewModel.tipPercentage,
                                         numberOfPeople: viewModel.numberOfPeople,
                                         tipAmount: viewModel.tipAmount,
                                         totalAmountWithTip: viewModel.totalAmountWithTip,
                                         totalPerPerson: viewModel.totalPerPerson,
                                         subtotalAmount: viewModel.hasTax ? viewModel.subtotalAmount : nil,
                                         taxAmount: viewModel.hasTax ? viewModel.sanitizedTaxAmount : nil,
                                         tipsOnTax: viewModel.hasTax ? viewModel.tipTaxBasis == .subtotalAndTax : nil)

        guard case .success = result else {
            HapticFeedbackPerformer.warning(isEnabled: settings.hapticsEnabled)
            dataErrorMessage = dataManager.lastError?.localizedDescription ?? String(localized: "Please try again.")
            return
        }

        HapticFeedbackPerformer.success(isEnabled: settings.hapticsEnabled)
        showingSaveSheet = false

        DispatchQueue.main.async {
            performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                viewModel.resetValues()
                viewModel.applySettingsDefaults(defaultTipPercentage: settings.defaultTipPercentage,
                                                defaultNumberOfPeople: settings.defaultNumberOfPeople)
            }
            successMessage = String(localized: "Tip calculation saved.")
        }
    }
}

/// Reports when a view inside a scroll view is scrolled out of sight. The API is iOS 18+,
/// so on earlier versions the view is always treated as visible.
private struct ScrollVisibilityModifier: ViewModifier {
    let onChange: (Bool) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollVisibilityChange(threshold: 0.05, onChange)
        } else {
            content
        }
    }
}

#Preview {
    CalculationView()
        .environmentObject(DataManager.preview)
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "CalculationPreview") ?? .standard))
}

#Preview("Calculator Demo") {
    let viewModel = CalculationViewModel(defaults: UserDefaults(suiteName: "CalculationDemoPreview") ?? .standard)
    viewModel.billAmount = 86.40
    viewModel.tipPercentage = 20
    viewModel.numberOfPeople = 3
    viewModel.roundingMode = .roundPerPersonUp
    return CalculationView(viewModel: viewModel)
        .environmentObject(DataManager.manyItemsPreview)
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "CalculationDemoSettingsPreview") ?? .standard))
}

#Preview("Calculator Error") {
    CalculationView()
        .environmentObject(DataManager.errorPreview)
        .environmentObject(TipSavvySettings(defaults: UserDefaults(suiteName: "CalculationErrorPreview") ?? .standard))
}
