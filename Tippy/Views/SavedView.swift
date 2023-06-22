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
                Text("No Saved Tips")
            } else {
                List() {
                    ForEach(dataManager.savedTips) { tip in
                        DisclosureGroup(tip.name ?? "") {
                            SavedDetailView(tip: tip)
                        }
                    }.onDelete { indexSet in
                        deleteTips(at: indexSet)
                    }
                }
                .navigationTitle("Saved Tips")
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
