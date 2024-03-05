//
//  SavedDetailViewModelTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 3/4/24.
//

import XCTest
@testable import Tippy
import CoreData
import Foundation

final class SavedDetailViewModelTests: XCTestCase {

    private var savedDetailViewModel: SavedDetailViewModel!
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SavedTip")
        
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Failed to load stores: \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        savedDetailViewModel = nil
        super.tearDown()
    }
    
    func test_tipValue_shouldBeTrue() {
        let savedTip = SavedTip(context: persistentContainer.viewContext)
        
        savedTip.name = "Sushi"
        savedTip.date = DateFormatter().date(from: "01/01/2024")
        savedTip.billAmount = 6.99 * 3
        savedTip.tipPercentage = 0.15
        savedTip.numberOfPeople = 3
        savedTip.tipAmount = savedTip.billAmount * savedTip.tipPercentage
        savedTip.totalAmountWithTip = savedTip.billAmount + savedTip.tipAmount
        savedTip.totalPerPerson = savedTip.totalAmountWithTip / Double(savedTip.numberOfPeople)
        
        
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("SavedDetailViewModelTests: test_tip_isNotNil error with saving persistentContainer")
        }
        
        savedDetailViewModel = SavedDetailViewModel(tip: savedTip)
        
        XCTAssertTrue(savedDetailViewModel.tip.name == "Sushi")
        XCTAssertTrue(savedDetailViewModel.tip.date == DateFormatter().date(from: "01/01/2024"))
        XCTAssertTrue(savedDetailViewModel.tip.billAmount == 6.99 * 3)
        XCTAssertTrue(savedDetailViewModel.tip.tipPercentage == 0.15)
        XCTAssertTrue(savedDetailViewModel.tip.numberOfPeople == 3)
        XCTAssertTrue(savedDetailViewModel.tip.tipAmount == savedDetailViewModel.tip.billAmount * savedDetailViewModel.tip.tipPercentage)
        XCTAssertTrue(savedDetailViewModel.tip.totalAmountWithTip == savedDetailViewModel.tip.billAmount + savedDetailViewModel.tip.tipAmount)
        XCTAssertTrue(savedDetailViewModel.tip.totalPerPerson == savedDetailViewModel.tip.totalAmountWithTip / Double(savedDetailViewModel.tip.numberOfPeople))
    }
}
