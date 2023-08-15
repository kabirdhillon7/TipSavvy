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
            let saveTipCalcLocalizedString = NSLocalizedString("save_tip_calculation", comment: "Save Tip Calculation")
            
            Form {
                // Bill Information from User
                let billInformationLocalizedString = NSLocalizedString("bill_information", comment: "Bill Information Header")
                Section {
                    let enterBillAmountLocalizedString = NSLocalizedString("enter_bill_amount", comment: "Enter Bill Amount Title")
                    let billAmountLocalizedString = NSLocalizedString("bill_amount", comment: "Bill Amount accessibilityLabel")
                    TextField(enterBillAmountLocalizedString,
                              value: $viewModel.billAmount,
                              format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .keyboardType(.decimalPad)
                    .focused($amountIsFocused)
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .accessibilityLabel(billAmountLocalizedString)
                    
                    let numberOfPeopleLocalizedString = NSLocalizedString("number_of_people", comment: "Number of People")
                    TextField(numberOfPeopleLocalizedString, value: $viewModel.numberOfPeople, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($numberOfPeopleIsFocused)
                        .onTapGesture {
                            hideKeyboard()
                        }
                        .accessibilityLabel(numberOfPeopleLocalizedString)
                } header: {
                    Text(billInformationLocalizedString)
                }
                
                // Selecting the Tip Percentage
                let selectTipAmountLocalizedString = NSLocalizedString("select_tip_amount", comment: "Select Tip Amount Header")
                Section {
                    HStack {
                        let tipPercentageLocalizedString = NSLocalizedString("tip_percentage", comment: "Tip Percentage accessibilityLabel")
                        let tipPercentageAccessibilityHint = NSLocalizedString("tip_percentage_accessibilityHint", comment: "Tip Percentage accessibilityHint")
                        Slider(value: $viewModel.tipPercentage, in: 0...30, step: 1)
                            .accessibilityLabel(tipPercentageLocalizedString)
                            .accessibilityHint(tipPercentageAccessibilityHint)
                        Text("\(viewModel.tipPercentage, specifier: "%.0f")%")
                            .fixedSize(horizontal: true, vertical: false)
                    }
                } header: {
                    Text(selectTipAmountLocalizedString)
                }
                
                // Final Totals
                let billTotalsLocalizedString = NSLocalizedString("bill_totals", comment: "Bill Totals")
                Section {
                    HStack {
                        let subtotalLocalizedString = NSLocalizedString("subtotal", comment: "Subtotal")
                        Text(subtotalLocalizedString)
                        Spacer()
                        let billAmount = viewModel.billAmount ?? 0
                        Text(billAmount,
                             format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        let tipLocalizedString = NSLocalizedString("tip", comment: "Tip")
                        Text(tipLocalizedString)
                        Spacer()
                        Text(viewModel.tipAmount,
                             format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        let totalWithTipLocalizedString = NSLocalizedString("total_with_tip", comment: "Total With Tip")
                        Text(totalWithTipLocalizedString)
                        Spacer()
                        Text(viewModel.totalAmountWithTip,
                             format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        let totalPerPersonLocalizedString = NSLocalizedString("total_per_person", comment: "Total Per Person")
                        Text(totalPerPersonLocalizedString)
                        Spacer()
                        Text(viewModel.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                } header: {
                    Text(billTotalsLocalizedString)
                }
                
                Section {
//                    let saveTipCalcLocalizedString = NSLocalizedString("save_tip_calculation", comment: "Save Tip Calculation")
                    let saveTipCalcAccessibilityHintLocalizedString = NSLocalizedString("save_tip_calculation_accessibilityHint", comment: "Save Tip Calculation accessibilityHint")
                    Button(saveTipCalcLocalizedString) {
                        showingSavedAlert = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel(saveTipCalcLocalizedString)
                    .accessibilityHint(saveTipCalcAccessibilityHintLocalizedString)
                    
                    let resetLocalizedString = NSLocalizedString("reset", comment: "Reset")
                    Button(resetLocalizedString) {
                        viewModel.resetValues()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                    .accessibilityLabel(resetLocalizedString)
                }
            }
            .navigationTitle("TipSavvy")
            .alert(saveTipCalcLocalizedString, isPresented: $showingSavedAlert,  actions: {
                let enterNameLocalizedString = NSLocalizedString("enter_name", comment: "Enter Name")
                TextField(enterNameLocalizedString, text: $viewModel.tipItemName)
                    .accessibilityLabel("Enter Tip Calculation Name")
                
                let okLocalizedString = NSLocalizedString("ok", comment: "OK Title")
                Button(okLocalizedString, role: nil) {
                    saveTipInfo()
                    
                    DispatchQueue.main.async {
                        viewModel.resetValues()
                    }
                }
                .accessibilityLabel(okLocalizedString)
                
                let cancelLocalizedString = NSLocalizedString("cancel", comment: "Cancel Title")
                Button(cancelLocalizedString, role: .cancel) {
                    viewModel.tipItemName = ""
                }
                .accessibilityLabel(cancelLocalizedString)
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
