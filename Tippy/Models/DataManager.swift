//
//  DataManager.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/11/23.
//

import CoreData
import Foundation

enum DataManagerError: LocalizedError, Equatable {
    case persistentStoreLoadFailed
    case saveFailed
    case deleteFailed
    case renameFailed
    case fetchFailed
    case emptyName

    var errorDescription: String? {
        switch self {
        case .persistentStoreLoadFailed:
            return String(localized: "TipSavvy could not load saved tips.")
        case .saveFailed:
            return String(localized: "TipSavvy could not save this tip.")
        case .deleteFailed:
            return String(localized: "TipSavvy could not delete this tip.")
        case .renameFailed:
            return String(localized: "TipSavvy could not rename this tip.")
        case .fetchFailed:
            return String(localized: "TipSavvy could not refresh saved tips.")
        case .emptyName:
            return String(localized: "Saved tip names cannot be blank.")
        }
    }
}

@MainActor
protocol SavedTipStore {
    var savedTips: [SavedTip] { get }
    var lastError: DataManagerError? { get }

    @discardableResult
    func saveTip(name: String,
                 note: String?,
                 billAmount: Double,
                 tipPercentage: Double,
                 numberOfPeople: Int,
                 tipAmount: Double,
                 totalAmountWithTip: Double,
                 totalPerPerson: Double,
                 date: Date,
                 subtotalAmount: Double?,
                 taxAmount: Double?,
                 tipsOnTax: Bool?) -> Result<SavedTip, DataManagerError>

    @discardableResult
    func deleteTips(_ tips: [SavedTip]) -> Result<Void, DataManagerError>

    @discardableResult
    func renameTip(_ tip: SavedTip, to name: String) -> Result<Void, DataManagerError>
}

/// Main data manager to handle saved tip calculations.
@MainActor
class DataManager: NSObject, ObservableObject {
    /// Dynamic properties that the UI will react to
    @Published var savedTips: [SavedTip] = [SavedTip]()
    @Published var lastError: DataManagerError?
    
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

        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { [weak self] _, error in
            if error != nil {
                Task { @MainActor in
                    self?.lastError = .persistentStoreLoadFailed
                }
            }
        }
        fetchSavedTips()
    }

    /// In-memory sample data for SwiftUI previews.
    static var preview: DataManager {
        let manager = DataManager(inMemory: true)
        _ = manager.saveTip(name: "Brunch",
                            billAmount: 48,
                            tipPercentage: 20,
                            numberOfPeople: 2,
                            tipAmount: 9.60,
                            totalAmountWithTip: 57.60,
                            totalPerPerson: 28.80,
                            date: Date())
        _ = manager.saveTip(name: "Dinner",
                            billAmount: 126,
                            tipPercentage: 18,
                            numberOfPeople: 3,
                            tipAmount: 22.68,
                            totalAmountWithTip: 148.68,
                            totalPerPerson: 49.56,
                            date: Date().addingTimeInterval(-86_400))
        return manager
    }

    static var emptyPreview: DataManager {
        DataManager(inMemory: true)
    }

    static var errorPreview: DataManager {
        let manager = DataManager.preview
        manager.lastError = .fetchFailed
        return manager
    }

    static var manyItemsPreview: DataManager {
        let manager = DataManager(inMemory: true)
        manager.seedDemoTips(count: 16)
        return manager
    }
    
    /// Saves a new tip to Core Data.
    @discardableResult
    func saveTip(name: String,
                 note: String? = nil,
                 billAmount: Double,
                 tipPercentage: Double,
                 numberOfPeople: Int,
                 tipAmount: Double,
                 totalAmountWithTip: Double,
                 totalPerPerson: Double,
                 date: Date = Date(),
                 subtotalAmount: Double? = nil,
                 taxAmount: Double? = nil,
                 tipsOnTax: Bool? = nil) -> Result<SavedTip, DataManagerError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            lastError = .emptyName
            return .failure(.emptyName)
        }
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)

        let context = container.viewContext
        
        let savedTip = SavedTip(context: context)
        savedTip.name = trimmedName
        savedTip.note = trimmedNote?.isEmpty == false ? trimmedNote : nil
        savedTip.date = date
        savedTip.billAmount = billAmount
        savedTip.tipPercentage = tipPercentage
        savedTip.numberOfPeople = Int64(numberOfPeople)
        savedTip.subtotalAmount = subtotalAmount.map(NSNumber.init(value:))
        savedTip.taxAmount = taxAmount.map(NSNumber.init(value:))
        savedTip.tipsOnTax = tipsOnTax.map(NSNumber.init(value:))
        savedTip.tipAmount = tipAmount
        savedTip.totalAmountWithTip = totalAmountWithTip
        savedTip.totalPerPerson = totalPerPerson
        
        do {
            try context.save()
            fetchSavedTips()
            lastError = nil
            return .success(savedTip)
        } catch {
            context.rollback()
            lastError = .saveFailed
            return .failure(.saveFailed)
        }
    }

    func seedDemoTips(count: Int = 8) {
        let demoTipNames = [
            "Friday Dinner",
            "Brunch Split",
            "Coffee Run",
            "Team Lunch",
            "Date Night",
            "Family Dinner",
            "Birthday Drinks",
            "Patio Brunch"
        ]

        for index in 1...count {
            let billAmount = Double(18 + index * 7)
            let tipPercentage = [15.0, 18.0, 20.0, 22.0][index % 4]
            let tipAmount = billAmount / 100 * tipPercentage
            let people = (index % 5) + 1
            let total = billAmount + tipAmount
            let name = demoTipNames[(index - 1) % demoTipNames.count]

            _ = saveTip(name: name,
                        billAmount: billAmount,
                        tipPercentage: tipPercentage,
                        numberOfPeople: people,
                        tipAmount: tipAmount,
                        totalAmountWithTip: total,
                        totalPerPerson: total / Double(people),
                        date: Date().addingTimeInterval(Double(-index) * 43_200))
        }
    }

    /// Deletes saved tip calculations at the supplied offsets.
    @discardableResult
    func deleteTips(at offsets: IndexSet) -> Result<Void, DataManagerError> {
        let tips = offsets.map { savedTips[$0] }
        return deleteTips(tips)
    }

    /// Deletes the supplied saved tip calculations.
    @discardableResult
    func deleteTips(_ tips: [SavedTip]) -> Result<Void, DataManagerError> {
        let context = container.viewContext

        for tip in tips {
            context.delete(tip)
        }

        do {
            try context.save()
            fetchSavedTips()
            lastError = nil
            return .success(())
        } catch {
            context.rollback()
            lastError = .deleteFailed
            return .failure(.deleteFailed)
        }
    }

    /// Deletes one saved tip calculation.
    @discardableResult
    func deleteTip(_ tip: SavedTip) -> Result<Void, DataManagerError> {
        deleteTips([tip])
    }

    /// Renames an existing saved tip calculation.
    @discardableResult
    func renameTip(_ tip: SavedTip, to name: String) -> Result<Void, DataManagerError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            lastError = .emptyName
            return .failure(.emptyName)
        }

        let context = container.viewContext
        tip.name = trimmedName

        do {
            try context.save()
            fetchSavedTips()
            lastError = nil
            return .success(())
        } catch {
            context.rollback()
            lastError = .renameFailed
            return .failure(.renameFailed)
        }
    }
    
    /// Fetches all saved tips from Core Data.
    @discardableResult
    private func fetchSavedTips() -> Result<[SavedTip], DataManagerError> {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<SavedTip> = SavedTip.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \SavedTip.date, ascending: false)
        ]
        
        do {
            savedTips = try context.fetch(fetchRequest)
            lastError = nil
            return .success(savedTips)
        } catch {
            savedTips = []
            lastError = .fetchFailed
            return .failure(.fetchFailed)
        }
    }
}

extension DataManager: SavedTipStore { }

extension SavedTip {
    var hasTaxBreakdown: Bool {
        (taxAmount?.doubleValue ?? 0) > 0
    }

    var savedSubtotalAmount: Double {
        subtotalAmount?.doubleValue ?? billAmount
    }

    var savedTaxAmount: Double {
        taxAmount?.doubleValue ?? 0
    }

    var savedTipsOnTax: Bool {
        tipsOnTax?.boolValue ?? false
    }

    func accessibilitySummary(currencyCode: String, dateFormat: Date.FormatStyle = .dateTime.month().day().year()) -> String {
        let savedName = name ?? String(localized: "Untitled Tip")
        let dateText = date.map { $0.formatted(dateFormat) }

        var parts = [savedName]
        if let dateText {
            parts.append(dateText)
        }
        if hasTaxBreakdown {
            parts.append(String(localized: "Subtotal") + ": " + savedSubtotalAmount.formatted(.currency(code: currencyCode)))
            parts.append(String(localized: "Tax") + ": " + savedTaxAmount.formatted(.currency(code: currencyCode)))
        }
        parts.append(String(localized: "Total With Tip") + ": " + totalAmountWithTip.formatted(.currency(code: currencyCode)))
        parts.append(String(localized: "Per Person") + ": " + totalPerPerson.formatted(.currency(code: currencyCode)))
        if let note, !note.isEmpty {
            parts.append(String(localized: "Note") + ": " + note)
        }

        return parts.joined(separator: ", ")
    }

    func shareText(currencyCode: String, dateFormat: Date.FormatStyle = .dateTime.month().day().year()) -> String {
        let savedName = name ?? String(localized: "Untitled Tip")
        let dateText = date.map { "\n" + String(localized: "Date") + ": " + $0.formatted(dateFormat) } ?? ""
        let taxText: String
        if hasTaxBreakdown {
            let basis = savedTipsOnTax ? String(localized: "Subtotal + Tax") : String(localized: "Subtotal")
            taxText = """

            \(String(localized: "Subtotal")): \(savedSubtotalAmount.formatted(.currency(code: currencyCode)))
            \(String(localized: "Tax")): \(savedTaxAmount.formatted(.currency(code: currencyCode)))
            \(String(localized: "Tip Basis")): \(basis)
            """
        } else {
            taxText = ""
        }
        let noteText = note?.isEmpty == false ? "\n" + String(localized: "Note") + ": " + (note ?? "") : ""

        return """
        \(savedName)\(dateText)
        \(String(localized: "Bill Amount")): \(billAmount.formatted(.currency(code: currencyCode)))\(taxText)
        \(String(localized: "Tip")): \(tipAmount.formatted(.currency(code: currencyCode))) (\(Int(tipPercentage))%)
        \(String(localized: "Total With Tip")): \(totalAmountWithTip.formatted(.currency(code: currencyCode)))
        \(String(localized: "Per Person")): \(totalPerPerson.formatted(.currency(code: currencyCode)))\(noteText)
        """
    }
}
