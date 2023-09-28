//
//  ContentView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

struct CalculationView: View {
    @EnvironmentObject var dataManager: DataManager
    
    @StateObject var viewModel = ContentViewModel()
    
    @FocusState private var amountIsFocused: Bool
    @FocusState private var numberOfPeopleIsFocused: Bool
    @FocusState private var nameIsFocused: Bool
    
    @State private var showingSavedAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Bill Information
                Section {
                    TextField(String(localized: "Enter Bil Amount"),
                              value: $viewModel.billAmount,
                              format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .keyboardType(.decimalPad)
                    .focused($amountIsFocused)
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .accessibilityLabel(String(localized: "Enter Bill Amount"))
                    
                    TextField(String(localized: "Number of People"),
                              value: $viewModel.numberOfPeople,
                              format: .number)
                        .keyboardType(.decimalPad)
                        .focused($numberOfPeopleIsFocused)
                        .onTapGesture {
                            hideKeyboard()
                        }
                        .accessibilityLabel(String(localized: "Number of People"))
                } header: {
                    Text(String(localized: "Bill Information"))
                }
                
                // MARK: Tip Percentage Slider
                Section {
                    HStack {
                        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1)
                            .accessibilityLabel(String(localized: "Tip Percentage Select"))
                            .accessibilityHint(String(localized: "Selects the Tip Percentage"))
                        Text("\(viewModel.tipPercentage, specifier: "%.0f")%")
                            .frame(width: 40, alignment: .trailing)
                    }
                } header: {
                    Text(String(localized: "Tip Amount"))
                }
                
                // MARK: Final Totals
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel(String(localized: "Save Tip Calculation"))
                    .accessibilityHint(String(localized: "Saves the Tip Calculation"))
                    
                    Button(String(localized: "Reset")) {
                        viewModel.resetValues()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
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
        }
    }
    
    func loadUserDefaults() {
        let defaults = UserDefaults.standard
        
        viewModel.billAmount = defaults.getBillAmount()
        viewModel.tipPercentage = defaults.double(forKey: "tipPercentage")
        viewModel.numberOfPeople = defaults.integer(forKey: "numberOfPeople")
    }
    
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
            .environmentObject(ContentViewModel())
    }
}

extension View {
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
    
    func getBillAmount() -> Double {
        return UserDefaults.standard.double(forKey: DefaultTypes.billAmount.rawValue)
    }
}
