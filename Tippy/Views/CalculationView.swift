//
//  ContentView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

/// A view that calculates a tip calculation.
struct CalculationView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @StateObject var viewModel = CalculationViewModel()
    
    @State private var showingSavedAlert = false
    @FocusState var keyboardFocusField: TipSavvyKeyboardField?

    private let tipPresets = [15.0, 18.0, 20.0, 25.0]
    private let localCurrency = Locale.current.currency?.identifier ?? "USD"
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Bill Information
                Section {
                    TextField(String(localized: "Enter Bill Amount"),
                              value: $viewModel.billAmount,
                              format: .currency(code: localCurrency))
                    .keyboardType(.decimalPad)
                    .focused($keyboardFocusField, equals: .billAmount)
                    .accessibilityLabel(String(localized: "Enter Bill Amount"))
                    
                    Stepper(value: $viewModel.numberOfPeople, in: 1...99) {
                        HStack {
                            Text(String(localized: "Number of People"))
                            Spacer()
                            Text(viewModel.numberOfPeople, format: .number)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(String(localized: "Number of People"))
                        .accessibilityValue("\(viewModel.numberOfPeople)")
                    }
                } header: {
                    Text(String(localized: "Bill Information"))
                }
                
                // MARK: Tip Amount: Percentage Slider
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 8)], spacing: 8) {
                        ForEach(tipPresets, id: \.self) { preset in
                            tipPresetButton(for: preset)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))

                    ViewThatFits(in: .horizontal) {
                        tipSliderRow
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(viewModel.tipPercentage, specifier: "%.0f")%")
                                .font(.headline)
                            tipSlider
                        }
                    }
                } header: {
                    Text(String(localized: "Tip Amount"))
                }
                
                // MARK: Bill Totals
                Section {
                    totalsSummaryPanel
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color.clear)
                } header: {
                    Text(String(localized: "Bill Totals"))
                }
                
                Section {
                    Button(String(localized: "Save Tip Calculation")) {
                        showingSavedAlert = true
                    }
                    .accessibilityLabel(String(localized: "Save Tip Calculation"))
                    .accessibilityHint(String(localized: "Saves the Tip Calculation"))
                    .disabled(!viewModel.hasValidCalculation)
                    
                    Button(String(localized: "Reset")) {
                        performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                            viewModel.resetValues()
                        }
                    }
                    .foregroundStyle(.red)
                    .accessibilityLabel(String(localized: "Reset"))
                }
            }
            .navigationTitle("TipSavvy")
            .alert(String(localized: "Save Tip Calculation"), isPresented: $showingSavedAlert,  actions: {
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
            })
            .onChange(of: viewModel.numberOfPeople, perform: { _ in
                viewModel.persistSmartDefaults()
            })
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.numberOfPeople)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.totalAmountWithTip)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.totalPerPerson)
            .toolbar {
                // MARK: Keyboard
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

    private var tipSliderRow: some View {
        HStack {
            tipSlider
            Text("\(viewModel.tipPercentage, specifier: "%.0f")%")
                .font(.body.monospacedDigit())
                .frame(minWidth: 48, alignment: .trailing)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func tipPresetButton(for preset: Double) -> some View {
        let isSelected = viewModel.tipPercentage == preset

        Button {
            performAnimated(.spring(response: 0.28, dampingFraction: 0.78)) {
                viewModel.tipPercentage = preset
                viewModel.persistSmartDefaults()
            }
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
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                viewModel.persistSmartDefaults()
            })
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.tipPercentage)
            .accessibilityLabel(String(localized: "Tip Percentage Selection"))
            .accessibilityValue("\(viewModel.tipPercentage, specifier: "%.0f")%")
            .accessibilityHint(String(localized: "Selects the Tip Percentage"))
    }

    private var totalsSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    totalsPrimaryColumn
                    Spacer(minLength: 16)
                    totalsSecondaryColumn
                }

                VStack(alignment: .leading, spacing: 12) {
                    totalsPrimaryColumn
                    totalsSecondaryColumn
                }
            }

            Divider()

            totalDetailRow(title: String(localized: "Subtotal"), amount: viewModel.billAmount ?? 0)
            totalDetailRow(title: String(localized: "Tip"), amount: viewModel.tipAmount)
        }
        .padding(16)
        .glassPanel(highContrast: colorSchemeContrast == .increased)
        .contentTransition(reduceMotion ? .identity : .opacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Bill Totals"))
        .accessibilityValue(viewModel.accessibilityTotalsSummary(currencyCode: localCurrency))
        .accessibilityIdentifier("Bill Totals Summary")
    }

    private var totalsPrimaryColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Total Per Person"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(viewModel.totalPerPerson, format: .currency(code: localCurrency))
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .minimumScaleFactor(0.85)
        }
    }

    private var totalsSecondaryColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Total With Tip"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(viewModel.totalAmountWithTip, format: .currency(code: localCurrency))
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func totalDetailRow(title: String, amount: Double) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(amount, format: .currency(code: localCurrency))
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.secondary)
                Text(amount, format: .currency(code: localCurrency))
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        }
        .font(.subheadline)
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
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Save Tip in Data Manager
        dataManager.saveTip(name: viewModel.tipItemName.trimmingCharacters(in: .whitespacesAndNewlines),
                            billAmount: billAmount,
                            tipPercentage: viewModel.tipPercentage,
                            numberOfPeople: viewModel.numberOfPeople,
                            tipAmount: viewModel.tipAmount,
                            totalAmountWithTip: viewModel.totalAmountWithTip,
                            totalPerPerson: viewModel.totalPerPerson)

        DispatchQueue.main.async {
            performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                viewModel.resetValues()
            }
        }
    }
}

#Preview {
    CalculationView()
        .environmentObject(DataManager(inMemory: true))
}

private struct GlassPanelModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let cornerRadius: CGFloat
    let interactive: Bool
    let highContrast: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let useHighContrast = highContrast || colorSchemeContrast == .increased

        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(interactive), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.primary.opacity(useHighContrast ? 0.45 : 0.18), lineWidth: useHighContrast ? 1.5 : 1)
                }
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.primary.opacity(useHighContrast ? 0.5 : 0.18), lineWidth: useHighContrast ? 1.5 : 1)
                }
                .shadow(color: .primary.opacity(useHighContrast ? 0.05 : 0.08), radius: 12, y: 6)
        }
    }
}

private extension View {
    func glassPanel(cornerRadius: CGFloat = 18, interactive: Bool = false, highContrast: Bool = false) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, interactive: interactive, highContrast: highContrast))
    }
}

private struct TipPresetButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        let highContrast = colorSchemeContrast == .increased

        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.accentColor.opacity(highContrast ? 0.28 : 0.16))
                }
            }
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(highContrast ? 0.35 : 0), lineWidth: isSelected || highContrast ? 1.5 : 0)
            }
            .glassPanel(cornerRadius: 16, interactive: true, highContrast: highContrast || isSelected)
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
    }
}

private struct SelectedAccessibilityTraitModifier: ViewModifier {
    let isSelected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            content.accessibilityAddTraits(.isSelected)
        } else {
            content
        }
    }
}
