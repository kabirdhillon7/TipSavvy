//
//  SavedDetailView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/12/23.
//

import SwiftUI

struct SavedDetailView: View {
    var tip: SavedTip
    
    var body: some View {
        ScrollView {
            VStack {
                if let name = tip.name {
                    Text(name)
                        .font(.largeTitle)
                        .frame(alignment: .center)
                        .bold()
                }
                Spacer(minLength: 2)
                
                if let date = tip.date {
                    Text(date, format: .dateTime.month().day().year())
                        .frame(alignment: .center)
                        .font(.subheadline)
                }
            }
            
            Spacer(minLength: 10)
            
            HStack {
                VStack {
                    Text("Bill Amount:")
                        .bold()
                        .font(.title3)
                    Text(tip.billAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.body)
                }
                
                VStack {
                    Text("Tip Percentage:")
                        .bold()
                        .font(.title3)
                    Text("\(Int(tip.tipPercentage))%")
                        .font(.body)
                }
            }
            
            VStack {
                Text("Number of People:")
                    .bold()
                    .font(.title3)
                Text("\(tip.numberOfPeople)")
                    .font(.body)
                
                Text("Tip Amount:")
                    .bold()
                    .font(.title3)
                Text(tip.tipAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.body)
                
                Text("Total Bill With Tip:")
                    .bold()
                    .font(.title3)
                Text(tip.totalAmountWithTip, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.body)
                
                Text("Total Per Person:")
                    .bold()
                    .font(.title3)
                Text(tip.totalPerPerson, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.body)
            }
            .lineSpacing(5)
        }
    }
}

//struct SavedDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedDetailView(tip: <#SavedTip#>)
//    }
//}
