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
                    HStack(spacing: 8) {
                        ForEach(tipPresets, id: \.self) { preset in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                    viewModel.tipPercentage = preset
                                    viewModel.persistSmartDefaults()
                                }
                            } label: {
                                Text("\(preset, specifier: "%.0f")%")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(TipPresetButtonStyle(isSelected: viewModel.tipPercentage == preset))
                            .accessibilityLabel("\(preset, specifier: "%.0f")%")
                            .accessibilityValue(viewModel.tipPercentage == preset ? String(localized: "Selected") : "")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))

                    HStack {
                        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1)
                            .onChange(of: viewModel.tipPercentage, perform: { _ in
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                viewModel.persistSmartDefaults()
                            })
                            .animation(.easeInOut(duration: 0.2), value: viewModel.tipPercentage)
                            .accessibilityLabel(String(localized: "Tip Percentage Selection"))
                            .accessibilityHint(String(localized: "Selects the Tip Percentage"))
                        Text("\(viewModel.tipPercentage, specifier: "%.0f")%")
                            .frame(width: 40, alignment: .trailing)
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
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            viewModel.resetValues()
                        }
                    }
                    .foregroundColor(.red)
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
            .animation(.easeInOut(duration: 0.2), value: viewModel.numberOfPeople)
            .animation(.easeInOut(duration: 0.2), value: viewModel.totalAmountWithTip)
            .animation(.easeInOut(duration: 0.2), value: viewModel.totalPerPerson)
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

    private var totalsSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Total Per Person"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalPerPerson, format: .currency(code: localCurrency))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(localized: "Total With Tip"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalAmountWithTip, format: .currency(code: localCurrency))
                        .fontWeight(.semibold)
                }
            }

            Divider()

            totalDetailRow(title: String(localized: "Subtotal"), amount: viewModel.billAmount ?? 0)
            totalDetailRow(title: String(localized: "Tip"), amount: viewModel.tipAmount)
        }
        .padding(16)
        .glassPanel()
        .contentTransition(.opacity)
        .accessibilityElement(children: .combine)
    }

    private func totalDetailRow(title: String, amount: Double) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(amount, format: .currency(code: localCurrency))
                .fontWeight(.medium)
        }
        .font(.subheadline)
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
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
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
    let cornerRadius: CGFloat
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(interactive), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
    }
}

private extension View {
    func glassPanel(cornerRadius: CGFloat = 18, interactive: Bool = false) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}

private struct TipPresetButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.accentColor.opacity(0.16))
                }
            }
            .glassPanel(cornerRadius: 16, interactive: true)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}
