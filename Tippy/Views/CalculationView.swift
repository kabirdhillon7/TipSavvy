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
                    HStack {
                        ForEach(tipPresets, id: \.self) { preset in
                            Button {
                                viewModel.tipPercentage = preset
                            } label: {
                                Text("\(preset, specifier: "%.0f")%")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.tipPercentage == preset ? .accentColor : .secondary)
                        }
                    }

                    HStack {
                        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1)
                            .onChange(of: viewModel.tipPercentage, perform: { _ in
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            })
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
                    HStack {
                        Text(String(localized: "Subtotal"))
                        Spacer()
                        let billAmount = viewModel.billAmount ?? 0
                        Text(billAmount,
                             format: .currency(code: localCurrency))
                    }
                    HStack {
                        Text(String(localized: "Tip"))
                        Spacer()
                        Text(viewModel.tipAmount,
                             format: .currency(code: localCurrency))
                    }
                    HStack {
                        Text(String(localized: "Total With Tip"))
                        Spacer()
                        Text(viewModel.totalAmountWithTip,
                             format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        Text(String(localized: "Total Per Person"))
                        Spacer()
                        Text(viewModel.totalPerPerson, format: .currency(code: localCurrency))
                            .fontWeight(.semibold)
                    }
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
                        viewModel.resetValues()
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
    
    /// Loads the user defaults for the bill amount, tip percentage, and number of people.
    func loadUserDefaults() {
        let defaults = UserDefaults.standard
        
        viewModel.billAmount = defaults.getBillAmount()
        viewModel.tipPercentage = defaults.double(forKey: "tipPercentage")
        viewModel.numberOfPeople = max(defaults.integer(forKey: "numberOfPeople"), 1)
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
            viewModel.resetValues()
        }
    }
}

#Preview {
    CalculationView()
        .environmentObject(DataManager(inMemory: true))
}

extension UserDefaults {
    enum DefaultTypes: String {
        case billAmount
        case tipPercentage
        case numberOfPeople
    }
    
    /// Returns the bill amount stored in user defaults.
    func getBillAmount() -> Double {
        return UserDefaults.standard.double(forKey: DefaultTypes.billAmount.rawValue)
    }
}
