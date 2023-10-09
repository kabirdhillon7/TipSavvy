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
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Bill Information
                Section {
                    TextField(String(localized: "Enter Bill Amount"),
                              value: $viewModel.billAmount,
                              format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .keyboardType(.decimalPad)
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .accessibilityLabel(String(localized: "Enter Bill Amount"))
                    
                    TextField(String(localized: "Number of People"),
                              value: $viewModel.numberOfPeople,
                              format: .number)
                        .keyboardType(.decimalPad)
                        .onTapGesture {
                            hideKeyboard()
                        }
                        .accessibilityLabel(String(localized: "Number of People"))
                } header: {
                    Text(String(localized: "Bill Information"))
                }
                
                // MARK: Tip Amount: Percentage Slider
                Section {
                    HStack {
                        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1)
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
                             format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        Text(String(localized: "Tip"))
                        Spacer()
                        Text(viewModel.tipAmount,
                             format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
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
                        Text(viewModel.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
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
                    .accessibilityLabel(String(localized: "Enter Tip Calculation Name"))
                
                Button(String(localized: "OK"), role: nil) {
                    saveTipInfo()
                    
                    DispatchQueue.main.async {
                        viewModel.resetValues()
                    }
                }
                .accessibilityLabel(String(localized: "Okay"))
                
                Button(String(localized: "Cancel"), role: .cancel) {
                    viewModel.tipItemName = ""
                }
                .accessibilityLabel(String(localized: "Cancel"))
            })
            .scrollDismissesKeyboard(.immediately)
        }
    }
    
    /// Loads the user defaults for the bill amount, tip percentage, and number of people.
    func loadUserDefaults() {
        let defaults = UserDefaults.standard
        
        viewModel.billAmount = defaults.getBillAmount()
        viewModel.tipPercentage = defaults.double(forKey: "tipPercentage")
        viewModel.numberOfPeople = defaults.integer(forKey: "numberOfPeople")
    }
    
    /// Saves the tip information to the data manager.
    func saveTipInfo() {
        guard let billAmount = viewModel.billAmount, let numberOfPeople = viewModel.numberOfPeople  else {
            return
        }
        dataManager.saveTip(name: viewModel.tipItemName,
                            billAmount: billAmount,
                            tipPercentage: viewModel.tipPercentage,
                            numberOfPeople: numberOfPeople,
                            tipAmount: viewModel.tipAmount,
                            totalAmountWithTip: viewModel.totalAmountWithTip,
                            totalPerPerson: viewModel.totalPerPerson)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CalculationView()
            .environmentObject(CalculationViewModel())
    }
}

extension View {
    /// Dismisses the keyboard if it is currently displaying.
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
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
