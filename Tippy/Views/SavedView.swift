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
        let savedTipsLocalizedString = NSLocalizedString("saved_tips", comment: "Saved Tips Navigation Title")
        
        NavigationStack {
            if dataManager.savedTips.isEmpty {
                let noSavedTipsLocalizedString = NSLocalizedString("no_saved_tips", comment: "No Saved Tips")
                Text(noSavedTipsLocalizedString)
                    .accessibilityLabel(noSavedTipsLocalizedString)
                    .navigationTitle(savedTipsLocalizedString)
            } else {
                List() {
                    ForEach(dataManager.savedTips) { tip in
                        DisclosureGroup() {
                            SavedDetailView(tip: tip)
                        } label: {
                            let savedTipAccessibilityHint = NSLocalizedString("saved_tip_accessibilityHint", comment: "Saved Tip Name accessibilityHint")
                            Text(tip.name ?? "")
                                .accessibilityLabel(tip.name ?? "")
                                .accessibilityHint(savedTipAccessibilityHint)
                        }
                    }.onDelete { indexSet in
                        deleteTips(at: indexSet)
                    }
                }
                .toolbar {
                    let editLocalizedString = NSLocalizedString("edit", comment: "Edit")
                    EditButton()
                        .accessibilityLabel(editLocalizedString)
                }
                .navigationTitle(savedTipsLocalizedString)
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
