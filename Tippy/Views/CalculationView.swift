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
                // Bill Information from User
                Section {
                    TextField("Enter Bill Amount",
                              value: $viewModel.billAmount,
                              format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .keyboardType(.decimalPad)
                    .focused($amountIsFocused)
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .accessibilityLabel("Bill Amount")
                    
                    TextField("Number of People", value: $viewModel.numberOfPeople, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($numberOfPeopleIsFocused)
                        .onTapGesture {
                            hideKeyboard()
                        }
                        .accessibilityLabel("Number of People")
                } header: {
                    Text("Bill Information")
                }
                
                // Selecting the Tip Percentage
                Section {
                    HStack {
                        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1)
                            .accessibilityLabel("Tip Percentage")
                            .accessibilityHint("Slide to select the desired tip percentage")
                        Text("\(viewModel.tipPercentage, specifier: "%.0f")%")
                            .fixedSize(horizontal: true, vertical: false)
                    }
                } header: {
                    Text("Select Tip Amount")
                }
                
                // Final Totals
                Section {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        let billAmount = viewModel.billAmount ?? 0
                        Text(billAmount,
                             format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        Text("Tip")
                        Spacer()
                        Text(viewModel.tipAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        Text("Total With Tip")
                        Spacer()
                        Text(viewModel.totalAmountWithTip, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        Text("Total Per Person")
                        Spacer()
                        Text(viewModel.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                } header: {
                    Text("Bill Totals")
                }
                
                Section {
                    Button("Save Tip Calculation") {
                        showingSavedAlert = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel("Save Tip Calculation")
                    .accessibilityHint("Adjust the tip percentage using the slider")
                    
                    Button("Reset") {
                        viewModel.resetValues()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                    .accessibilityLabel("Reset")
                }
            }
            .navigationTitle("TipSavvy")
            .alert("Save Tip Calculation", isPresented: $showingSavedAlert,  actions: {
                TextField("Enter Name", text: $viewModel.tipItemName)
                    .accessibilityLabel("Enter Tip Calculation Name")
                Button("OK", role: nil) {
                    saveTipInfo()
                    
                    DispatchQueue.main.async {
                        viewModel.resetValues()
                    }
                }
                .accessibilityLabel("OK")
                Button("Cancel", role: .cancel) {
                    viewModel.tipItemName = ""
                }
                .accessibilityLabel("Cancel")
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
