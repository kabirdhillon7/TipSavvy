//
//  ContentView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI
import UIKit

/// A view that calculates a tip calculation.
struct CalculationView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settings: TipSavvySettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @StateObject private var viewModel: CalculationViewModel

    @State private var showingSavedAlert = false
    @State private var showingSavedConfirmation = false
    @State private var dataErrorMessage: String?
    @State private var copiedValueLabel: String?
    @FocusState var keyboardFocusField: TipSavvyKeyboardField?

    private let localCurrency = Locale.current.currency?.identifier ?? "USD"

    @MainActor
    init(viewModel: CalculationViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? CalculationViewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let dataErrorMessage {
                        TipSavvyErrorBanner(message: dataErrorMessage) {
                            self.dataErrorMessage = nil
                            dataManager.lastError = nil
                        }
                    }
                    totalsSummaryPanel
                    billAmountCard
                    splitCard
                    tipCard
                    actionButtons
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TipSavvy")
            .alert(String(localized: "Save Tip Calculation"), isPresented: $showingSavedAlert, actions: {
                TextField(String(localized: "Enter Name"), text: $viewModel.tipItemName)
                    .autocorrectionDisabled()
                    .accessibilityLabel(String(localized: "Enter Tip Calculation Name"))

                Button(String(localized: "OK"), role: nil) {
                    saveTipInfo()
                }
                .disabled(!viewModel.canSaveTip)
                .accessibilityLabel(String(localized: "OK"))

                Button(String(localized: "Cancel"), role: .cancel) {
                    viewModel.tipItemName = ""
                }
                .accessibilityLabel(String(localized: "Cancel"))
            }, message: {
                if !viewModel.hasValidCalculation {
                    Text(viewModel.billValidationMessage ?? String(localized: "Enter a valid bill amount first."))
                }
            })
            .alert(String(localized: "Saved"), isPresented: $showingSavedConfirmation, actions: {
                Button(String(localized: "OK"), role: .cancel) { }
            }, message: {
                Text(String(localized: "Your tip calculation was saved."))
            })
            .onChange(of: viewModel.numberOfPeople, perform: { _ in
                viewModel.persistSmartDefaults()
            })
            .onChange(of: dataManager.lastError) { error in
                dataErrorMessage = error?.localizedDescription
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.numberOfPeople)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.totalAmountWithTip)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.totalPerPerson)
            .toolbar {
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

    private var billAmountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(String(localized: "Bill Amount"), systemImage: "receipt")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField(String(localized: "Enter Bill Amount"),
                      value: $viewModel.billAmount,
                      format: .currency(code: localCurrency))
                .font(.largeTitle.weight(.bold).monospacedDigit())
                .keyboardType(.decimalPad)
                .focused($keyboardFocusField, equals: .billAmount)
                .textFieldStyle(.plain)
                .accessibilityLabel(String(localized: "Enter Bill Amount"))

            if let message = viewModel.billValidationMessage, viewModel.billAmount != nil {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("Bill Validation Message")
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 22, interactive: true, highContrast: keyboardFocusField == .billAmount)
    }

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(String(localized: "Number of People"), systemImage: "person.2")
                .font(.headline)
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack {
                    peopleButton(systemImage: "minus", label: String(localized: "Decrease People"), isDisabled: viewModel.numberOfPeople <= 1) {
                        viewModel.numberOfPeople = max(1, viewModel.numberOfPeople - 1)
                        HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                    }

                    Spacer(minLength: 16)
                    peopleCount
                    Spacer(minLength: 16)

                    peopleButton(systemImage: "plus", label: String(localized: "Increase People"), isDisabled: viewModel.numberOfPeople >= 99) {
                        viewModel.numberOfPeople = min(99, viewModel.numberOfPeople + 1)
                        HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                    }
                }

                VStack(spacing: 12) {
                    peopleCount
                    HStack {
                        peopleButton(systemImage: "minus", label: String(localized: "Decrease People"), isDisabled: viewModel.numberOfPeople <= 1) {
                            viewModel.numberOfPeople = max(1, viewModel.numberOfPeople - 1)
                            HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                        }
                        Spacer()
                        peopleButton(systemImage: "plus", label: String(localized: "Increase People"), isDisabled: viewModel.numberOfPeople >= 99) {
                            viewModel.numberOfPeople = min(99, viewModel.numberOfPeople + 1)
                            HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                        }
                    }
                }
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 22)
        .accessibilityElement(children: .contain)
    }

    private var peopleCount: some View {
        VStack(spacing: 2) {
            Text(viewModel.numberOfPeople, format: .number)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .animatedTextChange(value: viewModel.numberOfPeople)
            Text(String(localized: "People"))
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
        } label: {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .frame(width: 48, height: 48)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Circle())
        .overlay {
            Circle()
                .strokeBorder(.primary.opacity(colorSchemeContrast == .increased ? 0.45 : 0.18), lineWidth: colorSchemeContrast == .increased ? 1.5 : 1)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(label)
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(String(localized: "Tip Amount"), systemImage: "percent")
                .font(.headline)
                .foregroundStyle(.secondary)

            serviceContextSection

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 8)], spacing: 8) {
                ForEach(viewModel.serviceContext.suggestedPresets, id: \.self) { preset in
                    tipPresetButton(for: preset)
                }
            }

            tipComparisonSection

            VStack(alignment: .leading, spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text(String(localized: "Custom Tip"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        tipPercentageText
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Custom Tip"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        tipPercentageText
                    }
                }
                tipSlider
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 22)
    }

    private var serviceContextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            serviceContextMenu
            .accessibilityLabel(String(localized: "Tip Service Context"))
            .accessibilityValue(viewModel.serviceContext.label)
            .accessibilityIdentifier("Tip Service Context")

            Text(serviceContextHelperText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("Tip Context Helper")
        }
    }

    private var serviceContextMenu: some View {
        Menu {
            ForEach(TipServiceContext.allCases) { context in
                serviceContextButton(for: context)
            }
        } label: {
            serviceContextMenuLabel
        }
    }

    private func serviceContextButton(for context: TipServiceContext) -> some View {
        Button {
            selectServiceContext(context)
        } label: {
            Label(context.label, systemImage: serviceContextSystemImage(for: context))
        }
    }

    private var serviceContextMenuLabel: some View {
        HStack(spacing: 10) {
            Label(String(localized: "Context"), systemImage: "sparkles")
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 10)
            Text(viewModel.serviceContext.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background {
            serviceContextShape
                .fill(serviceContextBackground)
        }
        .overlay {
            serviceContextBorder
        }
        .contentShape(serviceContextShape)
    }

    private var serviceContextBackground: some ShapeStyle {
        Color.primary.opacity(colorSchemeContrast == .increased ? 0.08 : 0.04)
    }

    private var serviceContextBorder: some View {
        serviceContextShape
            .strokeBorder(Color.primary.opacity(colorSchemeContrast == .increased ? 0.28 : 0.08), lineWidth: colorSchemeContrast == .increased ? 1.5 : 1)
    }

    private var serviceContextShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }

    private var serviceContextHelperText: String {
        viewModel.serviceContext.helperText + " " + String(localized: "Suggestions are general. Choose what feels right.")
    }

    private func serviceContextSystemImage(for context: TipServiceContext) -> String {
        context == viewModel.serviceContext ? "checkmark" : "circle"
    }

    private func selectServiceContext(_ context: TipServiceContext) {
        viewModel.serviceContext = context
        viewModel.persistSmartDefaults()
        HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
    }

    private var tipComparisonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Tip Comparison"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            let comparisons = viewModel.tipComparisons(for: viewModel.serviceContext.suggestedPresets)
            if comparisons.isEmpty {
                Label(String(localized: "Enter a bill amount to compare common tips."), systemImage: "chart.bar")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(comparisons) { comparison in
                        tipComparisonRow(comparison)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(colorSchemeContrast == .increased ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorSchemeContrast == .increased ? 0.28 : 0.08), lineWidth: colorSchemeContrast == .increased ? 1.5 : 1)
        }
        .accessibilityIdentifier("Tip Comparison")
    }

    private func tipComparisonRow(_ comparison: TipComparison) -> some View {
        let isSelected = viewModel.tipPercentage == comparison.percentage

        return Button {
            performAnimated(.spring(response: 0.28, dampingFraction: 0.78)) {
                viewModel.tipPercentage = comparison.percentage
                viewModel.persistSmartDefaults()
            }
            HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    tipComparisonPercent(comparison, isSelected: isSelected)
                    Spacer(minLength: 8)
                    tipComparisonAmounts(comparison)
                }

                VStack(alignment: .leading, spacing: 6) {
                    tipComparisonPercent(comparison, isSelected: isSelected)
                    tipComparisonAmounts(comparison)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(colorSchemeContrast == .increased ? 0.24 : 0.13))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(colorSchemeContrast == .increased ? 0.2 : 0.08), lineWidth: isSelected || colorSchemeContrast == .increased ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: String(localized: "%.0f%% tip comparison"), comparison.percentage))
        .accessibilityValue(String(localized: "Total \(comparison.totalAmountWithTip.formatted(.currency(code: localCurrency))), per person \(comparison.totalPerPerson.formatted(.currency(code: localCurrency)))"))
        .accessibilityHint(String(localized: "Applies this tip percentage"))
        .modifier(SelectedAccessibilityTraitModifier(isSelected: isSelected))
    }

    private func tipComparisonPercent(_ comparison: TipComparison, isSelected: Bool) -> some View {
        Label {
            Text("\(comparison.percentage, specifier: "%.0f")%")
                .font(.subheadline.weight(.semibold).monospacedDigit())
        } icon: {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
        .foregroundStyle(.primary)
    }

    private func tipComparisonAmounts(_ comparison: TipComparison) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(comparison.totalAmountWithTip, format: .currency(code: localCurrency))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Text(String(localized: "Per Person") + " " + comparison.totalPerPerson.formatted(.currency(code: localCurrency)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var tipPercentageText: some View {
        Text("\(viewModel.tipPercentage, specifier: "%.0f")%")
            .font(.headline.monospacedDigit())
            .lineLimit(1)
            .animatedTextChange(value: viewModel.tipPercentage)
    }

    @ViewBuilder
    private func tipPresetButton(for preset: Double) -> some View {
        let isSelected = viewModel.tipPercentage == preset

        Button {
            performAnimated(.spring(response: 0.28, dampingFraction: 0.78)) {
                viewModel.tipPercentage = preset
                viewModel.persistSmartDefaults()
            }
            HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
        } label: {
            Text("\(preset, specifier: "%.0f")%")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(TipPresetButtonStyle(isSelected: isSelected))
        .accessibilityLabel("\(preset, specifier: "%.0f")%")
        .accessibilityValue(isSelected ? String(localized: "Selected") : "")
        .modifier(SelectedAccessibilityTraitModifier(isSelected: isSelected))
    }

    private var tipSlider: some View {
        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1)
            .onChange(of: viewModel.tipPercentage, perform: { _ in
                HapticFeedbackPerformer.selection(isEnabled: settings.hapticsEnabled)
                viewModel.persistSmartDefaults()
            })
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.tipPercentage)
            .accessibilityLabel(String(localized: "Tip Percentage Selection"))
            .accessibilityValue("\(viewModel.tipPercentage, specifier: "%.0f")%")
            .accessibilityHint(String(localized: "Selects the Tip Percentage"))
    }

    private var totalsSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Bill Totals"))
                .font(.headline)
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    MetricCard(title: String(localized: "Total Per Person"), value: viewModel.totalPerPerson.formatted(.currency(code: localCurrency)), prominence: .primary)
                    MetricCard(title: String(localized: "Total With Tip"), value: viewModel.totalAmountWithTip.formatted(.currency(code: localCurrency)))
                }

                VStack(spacing: 12) {
                    MetricCard(title: String(localized: "Total Per Person"), value: viewModel.totalPerPerson.formatted(.currency(code: localCurrency)), prominence: .primary)
                    MetricCard(title: String(localized: "Total With Tip"), value: viewModel.totalAmountWithTip.formatted(.currency(code: localCurrency)))
                }
            }

            Divider()

            InfoRow(title: String(localized: "Subtotal"), value: (viewModel.billAmount ?? 0).formatted(.currency(code: localCurrency)))
            InfoRow(title: String(localized: "Tip"), value: viewModel.tipAmount.formatted(.currency(code: localCurrency)))

            VStack(alignment: .leading, spacing: 8) {
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

                if let roundingExplanation {
                    Label(roundingExplanation, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("Rounding Explanation")
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    copyButton(label: String(localized: "Copy Total"), value: viewModel.totalAmountWithTip.formatted(.currency(code: localCurrency)))
                    copyButton(label: String(localized: "Copy Per Person"), value: viewModel.totalPerPerson.formatted(.currency(code: localCurrency)))
                }

                VStack(spacing: 10) {
                    copyButton(label: String(localized: "Copy Total"), value: viewModel.totalAmountWithTip.formatted(.currency(code: localCurrency)))
                    copyButton(label: String(localized: "Copy Per Person"), value: viewModel.totalPerPerson.formatted(.currency(code: localCurrency)))
                }
            }

            if let copiedValueLabel {
                Text(copiedValueLabel + " " + String(localized: "copied"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(reduceMotion ? .identity : .opacity)
                    .accessibilityIdentifier("Copied Confirmation")
            }
        }
        .padding(18)
        .glassPanel(cornerRadius: 24, highContrast: colorSchemeContrast == .increased)
        .contentTransition(reduceMotion ? .identity : .opacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Bill Totals"))
        .accessibilityValue(viewModel.accessibilityTotalsSummary(currencyCode: localCurrency))
        .accessibilityIdentifier("Bill Totals Summary")
    }

    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                saveButton
                resetButton
            }

            VStack(spacing: 12) {
                saveButton
                resetButton
            }
        }
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

    private var saveButton: some View {
        Button {
            showingSavedAlert = true
        } label: {
            Label(String(localized: "Save"), systemImage: "tray.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.hasValidCalculation)
        .accessibilityLabel(String(localized: "Save Tip Calculation"))
        .accessibilityHint(viewModel.hasValidCalculation ? String(localized: "Saves the Tip Calculation") : String(localized: "Enter a bill amount greater than zero before saving"))
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                viewModel.resetValues()
                viewModel.applySettingsDefaults(defaultTipPercentage: settings.defaultTipPercentage,
                                                defaultNumberOfPeople: settings.defaultNumberOfPeople)
            }
            HapticFeedbackPerformer.warning(isEnabled: settings.hapticsEnabled)
        } label: {
            Label(String(localized: "Reset"), systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(String(localized: "Reset"))
    }

    private func performAnimated(_ animation: Animation, _ updates: () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }

    private func copyButton(label: String, value: String) -> some View {
        Button {
            UIPasteboard.general.string = value
            copiedValueLabel = label
            HapticFeedbackPerformer.lightImpact(isEnabled: settings.hapticsEnabled)
        } label: {
            Label(label, systemImage: "doc.on.doc")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(!viewModel.hasValidCalculation)
        .accessibilityLabel(label)
    }

    /// Saves the tip information to the data manager.
    func saveTipInfo() {
        guard let billAmount = viewModel.billAmount, viewModel.canSaveTip else {
            return
        }

        let result = dataManager.saveTip(name: viewModel.tipItemName.trimmingCharacters(in: .whitespacesAndNewlines),
                                         billAmount: billAmount,
                                         tipPercentage: viewModel.tipPercentage,
                                         numberOfPeople: viewModel.numberOfPeople,
                                         tipAmount: viewModel.tipAmount,
                                         totalAmountWithTip: viewModel.totalAmountWithTip,
                                         totalPerPerson: viewModel.totalPerPerson)

        guard case .success = result else {
            HapticFeedbackPerformer.warning(isEnabled: settings.hapticsEnabled)
            dataErrorMessage = dataManager.lastError?.localizedDescription ?? String(localized: "Please try again.")
            return
        }

        HapticFeedbackPerformer.success(isEnabled: settings.hapticsEnabled)

        DispatchQueue.main.async {
            performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                viewModel.resetValues()
                viewModel.applySettingsDefaults(defaultTipPercentage: settings.defaultTipPercentage,
                                                defaultNumberOfPeople: settings.defaultNumberOfPeople)
            }
            showingSavedConfirmation = true
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
