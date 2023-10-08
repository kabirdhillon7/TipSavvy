//
//  HistoryView.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/8/23.
//

import SwiftUI

struct SavedView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationStack {
            if dataManager.savedTips.isEmpty {
                Image(systemName: "percent")
                    .fontWeight(.medium)
                    .font(.system(size: 50))
                    .foregroundColor(Color(UIColor.lightGray))
                Spacer()
                    .frame(height: 5)
                Text(String(localized: "No Saved Tips"))
                    .fontWeight(.medium)
                    .foregroundStyle(Color(UIColor.lightGray))
                    .accessibilityLabel(String(localized: "No Saved Tips"))
                    .navigationTitle(String(localized: "Saved Tips"))
            } else {
                List() {
                    ForEach(dataManager.savedTips) { tip in
                        DisclosureGroup() {
                            SavedDetailView(tip: tip)
                        } label: {
                            Text(tip.name ?? "")
                                .accessibilityLabel(tip.name ?? "")
                        }
                    }.onDelete { indexSet in
                        deleteTips(at: indexSet)
                    }
                }
                .toolbar {
                    EditButton()
                        .accessibilityLabel(String(localized: "Edit"))
                }
                .navigationTitle(String(localized: "Saved Tips"))
            }
        }
    }
    
    func deleteTips(at offsets: IndexSet) {
        // First, delete the selected tips from Core Data
        let context = dataManager.container.viewContext
        for index in offsets {
            let tip = dataManager.savedTips[index]
            context.delete(tip)
        }
        
        dataManager.savedTips.remove(atOffsets: offsets)
        
        // Save the changes
        do {
            try context.save()
        } catch {
            fatalError("Failed to delete tips: \(error)")
        }
    }
}

//struct SavedView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedView()
//    }
//}
