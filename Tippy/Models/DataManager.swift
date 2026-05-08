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
    let container: NSPersistentContainer
    
    /// Default init method. Load the Core Data container
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SavedTip")

        super.init()

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        fetchSavedTips()
    }
    
    /// Saves a new tip to Core Data.
    func saveTip(name: String, billAmount: Double, tipPercentage: Double, numberOfPeople: Int, tipAmount: Double, totalAmountWithTip: Double, totalPerPerson: Double, date: Date = Date()) {
        let context = container.viewContext
        
        let savedTip = SavedTip(context: context)
        savedTip.name = name
        savedTip.date = date
        savedTip.billAmount = billAmount
        savedTip.tipPercentage = tipPercentage
        savedTip.numberOfPeople = Int64(numberOfPeople)
        savedTip.tipAmount = tipAmount
        savedTip.totalAmountWithTip = totalAmountWithTip
        savedTip.totalPerPerson = totalPerPerson
        
        do {
            try context.save()
            fetchSavedTips()
        } catch {
            fatalError("Failed to save tip: \(error)")
        }
    }

    /// Deletes saved tip calculations at the supplied offsets.
    func deleteTips(at offsets: IndexSet) {
        let tips = offsets.map { savedTips[$0] }
        deleteTips(tips)
    }

    /// Deletes the supplied saved tip calculations.
    func deleteTips(_ tips: [SavedTip]) {
        let context = container.viewContext

        for tip in tips {
            context.delete(tip)
        }

        do {
            try context.save()
            fetchSavedTips()
        } catch {
            fatalError("Failed to delete tips: \(error)")
        }
    }

    /// Renames an existing saved tip calculation.
    func renameTip(_ tip: SavedTip, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        let context = container.viewContext
        tip.name = trimmedName

        do {
            try context.save()
            fetchSavedTips()
        } catch {
            fatalError("Failed to rename tip: \(error)")
        }
    }
    
    /// Fetches all saved tips from Core Data.
    private func fetchSavedTips() {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<SavedTip> = SavedTip.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \SavedTip.date, ascending: false)
        ]
        
        do {
            savedTips = try context.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch saved tips: \(error)")
        }
    }
}

extension SavedTip {
    func accessibilitySummary(currencyCode: String, dateFormat: Date.FormatStyle = .dateTime.month().day().year()) -> String {
        let savedName = name ?? String(localized: "Untitled Tip")
        let dateText = date.map { $0.formatted(dateFormat) }

        var parts = [savedName]
        if let dateText {
            parts.append(dateText)
        }
        parts.append(String(localized: "Total With Tip") + ": " + totalAmountWithTip.formatted(.currency(code: currencyCode)))
        parts.append(String(localized: "Per Person") + ": " + totalPerPerson.formatted(.currency(code: currencyCode)))

        return parts.joined(separator: ", ")
    }
}
