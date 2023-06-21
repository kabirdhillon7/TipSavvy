//
//  ContentView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

struct ContentView: View {
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
                            .accessibilityHint("Adjust the tip percentage using the slider")
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
                        if let billAmount = viewModel.billAmount {
                            Text(billAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        } else {
                            Text(0, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        }
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
                    TextField("Enter Name", text: $viewModel.tipItemName)
                        .focused($nameIsFocused)
                        .onTapGesture {
                            hideKeyboard()
                        }
                } header: {
                    Text("Save Tip Information")
                }
                Section {
                    Button("Save Tip Calculation", action: saveTipInfo)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .alert("Tip Calculation Saved", isPresented: $showingSavedAlert) {
                            Button("OK", role: .none) { }
                        }
                }
            }
            .navigationTitle("TipSavvy")
        }
    }
    
    func loadUserDefaults() {
        let defaults = UserDefaults.standard
        viewModel.billAmount = defaults.double(forKey: "billAmount")
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
        
        showingSavedAlert = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentViewModel())
    }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}
