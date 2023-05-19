//
//  ContentView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/14/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    
    @FocusState private var amountIsFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                
                // Bill Information from User
                Section {
                    HStack {
                        Text("Enter Bill Amount:")
                        Spacer(minLength: 10)
                        TextField("Amount", value: $viewModel.billAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                            .focused($amountIsFocused)
                            .onTapGesture {
                                hideKeyboard()
                            }
                    }
                    Picker("Number of People", selection: $viewModel.numberOfPeople) {
                        ForEach(2..<100) {
                            Text("\($0) people")
                        }
                    }
                } header: {
                    Text("Bill Information")
                }
                
                // Selecting the Tip Percentage
                Section {
                    Slider(value: $viewModel.tipPercentage, in: 0...25, step: 1)
                    Text("Tip Percentage: \(viewModel.tipPercentage, specifier: "%.0f")%")
                        .fixedSize(horizontal: true, vertical: false)
                } header: {
                    Text("Select a Tip Amount")
                }
                
                // Final Totals
                Section {
                    HStack {
                        Text("With Tip")
                        Spacer()
                        Text(viewModel.totalAmountWithTip, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                    HStack {
                        Text("Per Person")
                        Spacer()
                        Text(viewModel.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                } header: {
                    Text("Bill Totals")
                }
            }
            .navigationTitle("Tippy")
        }
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
