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
            ScrollView {
                VStack(spacing: 18) {
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
            })
            .onChange(of: viewModel.numberOfPeople, perform: { _ in
                viewModel.persistSmartDefaults()
            })
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
                    }

                    Spacer(minLength: 16)
                    peopleCount
                    Spacer(minLength: 16)

                    peopleButton(systemImage: "plus", label: String(localized: "Increase People"), isDisabled: viewModel.numberOfPeople >= 99) {
                        viewModel.numberOfPeople = min(99, viewModel.numberOfPeople + 1)
                    }
                }

                VStack(spacing: 12) {
                    peopleCount
                    HStack {
                        peopleButton(systemImage: "minus", label: String(localized: "Decrease People"), isDisabled: viewModel.numberOfPeople <= 1) {
                            viewModel.numberOfPeople = max(1, viewModel.numberOfPeople - 1)
                        }
                        Spacer()
                        peopleButton(systemImage: "plus", label: String(localized: "Increase People"), isDisabled: viewModel.numberOfPeople >= 99) {
                            viewModel.numberOfPeople = min(99, viewModel.numberOfPeople + 1)
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

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 8)], spacing: 8) {
                ForEach(tipPresets, id: \.self) { preset in
                    tipPresetButton(for: preset)
                }
            }

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

    private var saveButton: some View {
        Button {
            showingSavedAlert = true
        } label: {
            Label(String(localized: "Save Tip Calculation"), systemImage: "tray.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.hasValidCalculation)
        .accessibilityLabel(String(localized: "Save Tip Calculation"))
        .accessibilityHint(String(localized: "Saves the Tip Calculation"))
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            performAnimated(.spring(response: 0.32, dampingFraction: 0.82)) {
                viewModel.resetValues()
            }
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

    /// Saves the tip information to the data manager.
    func saveTipInfo() {
        guard let billAmount = viewModel.billAmount, viewModel.canSaveTip else {
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

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
        .environmentObject(DataManager.preview)
}
