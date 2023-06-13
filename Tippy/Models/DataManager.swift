//
//  DataManager.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/11/23.
//

import CoreData
import Foundation

/// Main data manager to handle the todo items
class DataManager: NSObject, ObservableObject {
    /// Dynamic properties that the UI will react to
    @Published var savedTips: [SavedTip] = [SavedTip]()
    
    /// Add the Core Data container with the model name
    let container: NSPersistentContainer = NSPersistentContainer(name: "SavedTip")
    
    /// Default init method. Load the Core Data container
    override init() {
        super.init()
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        fetchSavedTips()
    }
    
    func saveTip(name: String, billAmount: Double, tipPercentage: Double, numberOfPeople: Int, tipAmount: Double, totalAmountWithTip: Double, totalPerPerson: Double) {
        let context = container.viewContext
        
        let savedTip = SavedTip(context: context)
        savedTip.name = name
        savedTip.date = Date()
        savedTip.billAmount = billAmount
        savedTip.tipPercentage = tipPercentage
        savedTip.numberOfPeople = Int64(numberOfPeople)
        savedTip.tipAmount = tipAmount
        savedTip.totalAmountWithTip = totalAmountWithTip
        savedTip.totalPerPerson = totalPerPerson
        
        do {
            try context.save()
            savedTips.append(savedTip)
        } catch {
            fatalError("Failed to save tip: \(error)")
        }
    }
    
    private func fetchSavedTips() {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<SavedTip> = SavedTip.fetchRequest()
        
        do {
            savedTips = try context.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch saved tips: \(error)")
        }
    }
}
