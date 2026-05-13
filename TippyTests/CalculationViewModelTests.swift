//
//  CalculationViewModelTests.swift
//  TippyTests
//
//  Created by Kabir Dhillon on 10/9/23.
//

import XCTest
import CoreData
@testable import Tippy

@MainActor
final class CalculationViewModelTests: XCTestCase {
    
    private var calculationViewModel: CalculationViewModel!
    private var defaults: UserDefaults!
    private var savedTipContainers: [NSPersistentContainer] = []
    
    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "CalculationViewModelTests")
        defaults.removePersistentDomain(forName: "CalculationViewModelTests")
        calculationViewModel = CalculationViewModel(defaults: defaults)
    }
    
    override func tearDown() {
        calculationViewModel = nil
        savedTipContainers.removeAll()
        defaults.removePersistentDomain(forName: "CalculationViewModelTests")
        defaults = nil
        super.tearDown()
    }

    // naming test_[what]_[expected result]
    // given, when, then
    
    // Regular Use
    func test_totalAmountWithTip_shouldBeTrue() {
        calculationViewModel.billAmount = 25.00
        calculationViewModel.tipPercentage = 15
        
        let totalWithTip = calculationViewModel.totalAmountWithTip
        
        XCTAssertEqual(totalWithTip, 28.75)
    }
    
    func test_billAmount_shouldAcceptLargeValue() {
        calculationViewModel.billAmount = 1_000_000_000_000_000
        calculationViewModel.tipPercentage = 20
        
        let total = calculationViewModel.totalAmountWithTip
        let expectedValue = 1_000_000_000_000_000 + (1_000_000_000_000_000 * 0.20)
        
        XCTAssertEqual(total, expectedValue)
    }
    
    // Large Bill Amount
    func test_totalPerPerson_shouldBeTrue() {
        calculationViewModel.billAmount = 129.99
        calculationViewModel.tipPercentage = 20
        calculationViewModel.numberOfPeople = 5
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        let totalPerPersonRounded = String(format: "%.2f", totalPerPerson)
        
        XCTAssertEqual(Double(totalPerPersonRounded), 31.2)
    }
    
    // Max People Split
    func test_totalPerPerson_shouldBeZero() {
        calculationViewModel.billAmount = 0
        calculationViewModel.tipPercentage = 0
        calculationViewModel.numberOfPeople = 99
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 0)
    }
    
    func test_TotalPerPerson_withInvalidTotal() {
        calculationViewModel.billAmount = 100
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 0
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertEqual(totalPerPerson, 0)
    }
    
    func test_TotalPerPerson_withNaNTotal() {
        calculationViewModel.billAmount = Double.nan
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 2
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertEqual(totalPerPerson, 0)
    }
    
    func test_TotalPerPerson_withInfiniteTotal() {
        calculationViewModel.billAmount = Double.infinity
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 2
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertEqual(totalPerPerson, 0)
    }
    
    // Check for 0 bill total, but multiple people
    func test_totalPerPerson_shouldReturnTrueForZeroBillAmount() {
        calculationViewModel.billAmount = 0
        calculationViewModel.numberOfPeople = 10
        calculationViewModel.tipPercentage = 10
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 0)
    }

    // Min Tip
    func test_tipPercentage_shouldAcceptMinimum() {
        calculationViewModel.tipPercentage = 0
        calculationViewModel.billAmount = 100
        
        let total = calculationViewModel.totalAmountWithTip
        
        XCTAssertEqual(total, 100)
    }
    
    // Max Tip
    func test_tipPercentage_shouldAcceptMaximum() {
        calculationViewModel.tipPercentage = 25
        calculationViewModel.billAmount = 100
        
        let total = calculationViewModel.totalAmountWithTip
        
        XCTAssertEqual(total, 125)
    }
    
    // Zero Bill Amount
    func test_totalAmountWithTip_shouldBeZero() {
        calculationViewModel.billAmount = 0
        calculationViewModel.tipPercentage = 0
        
        let total = calculationViewModel.totalAmountWithTip
        
        XCTAssertTrue(total == 0)
    }
    
    // Min People Split
    func test_numberOfPeople_shouldAcceptMin() {
        calculationViewModel.numberOfPeople = 2
        calculationViewModel.billAmount = 6
        calculationViewModel.tipPercentage = 0
        
        let totalPerPerson = calculationViewModel.totalPerPerson
        
        XCTAssertTrue(totalPerPerson == 3)
    }
    
    // tip amount
    func test_tipAmount_shouldBeEqual() {
        calculationViewModel.billAmount = 100
        calculationViewModel.tipPercentage = 15
        
        let tip = calculationViewModel.tipAmount
        
        XCTAssertEqual(tip, 15)
    }
    
    func test_tipAmount_shouldBeEqualForNilBillAmount() {
        calculationViewModel.billAmount = nil
        calculationViewModel.tipPercentage = 15
        
        let tipAmount = calculationViewModel.tipAmount
        
        XCTAssertEqual(tipAmount, 0)
    }
    
    func test_tipItemName_shouldBeEmptyString() {
        calculationViewModel.tipItemName = ""
        
        XCTAssertEqual("", calculationViewModel.tipItemName)
    }
    
    func test_tipItemName_shouldBeEqual() {
        calculationViewModel.tipItemName = "Pizza"
        
        XCTAssertEqual("Pizza", calculationViewModel.tipItemName)
    }
    
    func test_resetValues_shouldResetValues() {
        calculationViewModel.billAmount = 15.99
        calculationViewModel.tipPercentage = 15
        calculationViewModel.numberOfPeople = 2
        calculationViewModel.roundingMode = .roundTotalUp
        calculationViewModel.tipItemName = "Sandwiches"
                
        calculationViewModel.resetValues()
        
        XCTAssertNil(calculationViewModel.billAmount)
        XCTAssertEqual(calculationViewModel.tipPercentage, 18.0)
        XCTAssertEqual(calculationViewModel.numberOfPeople, 1)
        XCTAssertEqual(calculationViewModel.roundingMode, .none)
        XCTAssertEqual(calculationViewModel.tipItemName, "")
    }
    
    func test_resetValues_shouldReturnTrue() {
        calculationViewModel.resetValues()
        
        XCTAssertTrue(calculationViewModel.billAmount == nil)
        XCTAssertTrue(calculationViewModel.tipPercentage == 18)
        XCTAssertTrue(calculationViewModel.numberOfPeople == 1)
        XCTAssertTrue(calculationViewModel.roundingMode == .none)
        XCTAssertTrue(calculationViewModel.tipItemName == "")
    }

    func test_init_withSavedPeopleBelowMinimum_shouldClampToOne() {
        defaults.set(0, forKey: "numberOfPeople")

        calculationViewModel = CalculationViewModel(defaults: defaults)

        XCTAssertEqual(calculationViewModel.numberOfPeople, 1)
    }

    func test_init_withSavedPeopleAboveMaximum_shouldClampToNinetyNine() {
        defaults.set(120, forKey: "numberOfPeople")

        calculationViewModel = CalculationViewModel(defaults: defaults)

        XCTAssertEqual(calculationViewModel.numberOfPeople, 99)
    }

    func test_init_withSavedTipBelowMinimum_shouldClampToZero() {
        defaults.set(-5.0, forKey: "tipPercentage")

        calculationViewModel = CalculationViewModel(defaults: defaults)

        XCTAssertEqual(calculationViewModel.tipPercentage, 0)
    }

    func test_init_withSavedTipAboveMaximum_shouldClampToThirty() {
        defaults.set(35.0, forKey: "tipPercentage")

        calculationViewModel = CalculationViewModel(defaults: defaults)

        XCTAssertEqual(calculationViewModel.tipPercentage, 30)
    }

    func test_resetValues_shouldPersistDefaultTipAndPeople() {
        calculationViewModel.tipPercentage = 20
        calculationViewModel.numberOfPeople = 4

        calculationViewModel.resetValues()

        XCTAssertEqual(defaults.double(forKey: "tipPercentage"), 18)
        XCTAssertEqual(defaults.integer(forKey: "numberOfPeople"), 1)
    }

    func test_hasValidCalculation_withMissingBill_shouldBeFalse() {
        calculationViewModel.billAmount = nil
        calculationViewModel.numberOfPeople = 1

        XCTAssertFalse(calculationViewModel.hasValidCalculation)
    }

    func test_billValidationMessage_withZeroBill_shouldExplainRequirement() {
        calculationViewModel.billAmount = 0

        XCTAssertEqual(calculationViewModel.billValidationMessage, "Bill amount must be greater than zero.")
    }

    func test_settings_shouldPersistDefaultTipPeopleAndHaptics() {
        let settings = TipSavvySettings(defaults: defaults)

        settings.defaultTipPercentage = 22
        settings.defaultNumberOfPeople = 3
        settings.hapticsEnabled = false

        let restoredSettings = TipSavvySettings(defaults: defaults)

        XCTAssertEqual(restoredSettings.defaultTipPercentage, 22)
        XCTAssertEqual(restoredSettings.defaultNumberOfPeople, 3)
        XCTAssertFalse(restoredSettings.hapticsEnabled)
    }

    func test_applySettingsDefaults_shouldUpdateCalculationDefaults() {
        calculationViewModel.tipPercentage = 12
        calculationViewModel.numberOfPeople = 4

        calculationViewModel.applySettingsDefaults(defaultTipPercentage: 20, defaultNumberOfPeople: 2)

        XCTAssertEqual(calculationViewModel.tipPercentage, 20)
        XCTAssertEqual(calculationViewModel.numberOfPeople, 2)
    }

    func test_hasValidCalculation_withZeroBill_shouldBeFalse() {
        calculationViewModel.billAmount = 0
        calculationViewModel.numberOfPeople = 1

        XCTAssertFalse(calculationViewModel.hasValidCalculation)
    }

    func test_canSaveTip_withBlankName_shouldBeFalse() {
        calculationViewModel.billAmount = 25
        calculationViewModel.numberOfPeople = 2
        calculationViewModel.tipItemName = "   "

        XCTAssertFalse(calculationViewModel.canSaveTip)
    }

    func test_canSaveTip_withValidCalculationAndName_shouldBeTrue() {
        calculationViewModel.billAmount = 25
        calculationViewModel.numberOfPeople = 2
        calculationViewModel.tipItemName = "Lunch"

        XCTAssertTrue(calculationViewModel.canSaveTip)
    }

    func test_accessibilityTotalsSummary_shouldIncludeCalculatedAmounts() {
        calculationViewModel.billAmount = 100
        calculationViewModel.tipPercentage = 20
        calculationViewModel.numberOfPeople = 4

        let summary = calculationViewModel.accessibilityTotalsSummary(currencyCode: "USD")

        XCTAssertTrue(summary.contains("Subtotal"))
        XCTAssertTrue(summary.contains("100.00"))
        XCTAssertTrue(summary.contains("Tip"))
        XCTAssertTrue(summary.contains("20.00"))
        XCTAssertTrue(summary.contains("Total With Tip"))
        XCTAssertTrue(summary.contains("120.00"))
        XCTAssertTrue(summary.contains("Total Per Person"))
        XCTAssertTrue(summary.contains("30.00"))
    }

    func test_roundingMode_none_shouldKeepExactTotalAndPerPerson() {
        calculationViewModel.billAmount = 10
        calculationViewModel.tipPercentage = 18
        calculationViewModel.numberOfPeople = 3
        calculationViewModel.roundingMode = .none

        XCTAssertEqual(calculationViewModel.totalAmountWithTip, 11.8, accuracy: 0.001)
        XCTAssertEqual(calculationViewModel.totalPerPerson, 3.933, accuracy: 0.001)
    }

    func test_roundingMode_roundTotalUp_shouldRoundTotalBeforeSplitting() {
        calculationViewModel.billAmount = 10
        calculationViewModel.tipPercentage = 18
        calculationViewModel.numberOfPeople = 3
        calculationViewModel.roundingMode = .roundTotalUp

        XCTAssertEqual(calculationViewModel.totalAmountWithTip, 12)
        XCTAssertEqual(calculationViewModel.totalPerPerson, 4)
    }

    func test_roundingMode_roundPerPersonUp_shouldRoundEachPersonAndReflectCollectedTotal() {
        calculationViewModel.billAmount = 10
        calculationViewModel.tipPercentage = 18
        calculationViewModel.numberOfPeople = 3
        calculationViewModel.roundingMode = .roundPerPersonUp

        XCTAssertEqual(calculationViewModel.totalPerPerson, 4)
        XCTAssertEqual(calculationViewModel.totalAmountWithTip, 12)
    }

    func test_roundingMode_shouldPersist() {
        calculationViewModel.roundingMode = .roundPerPersonUp

        calculationViewModel.persistSmartDefaults()
        calculationViewModel = CalculationViewModel(defaults: defaults)

        XCTAssertEqual(calculationViewModel.roundingMode, .roundPerPersonUp)
    }

    func test_init_withInvalidSavedServiceContext_shouldFallbackToRestaurant() {
        defaults.set("not-a-context", forKey: "serviceContext")

        calculationViewModel = CalculationViewModel(defaults: defaults)

        XCTAssertEqual(calculationViewModel.serviceContext, .restaurant)
    }

    func test_serviceContext_shouldPersist() {
        calculationViewModel.serviceContext = .coffee

        calculationViewModel.persistSmartDefaults()
        calculationViewModel = CalculationViewModel(defaults: defaults)

        XCTAssertEqual(calculationViewModel.serviceContext, .coffee)
    }

    func test_serviceContextChange_shouldNotResetSelectedTipPercentage() {
        calculationViewModel.tipPercentage = 22

        calculationViewModel.serviceContext = .delivery

        XCTAssertEqual(calculationViewModel.tipPercentage, 22)
    }

    func test_tipComparisons_withValidBill_shouldReturnRowsForPresets() {
        calculationViewModel.billAmount = 100
        calculationViewModel.numberOfPeople = 2

        let comparisons = calculationViewModel.tipComparisons(for: [15, 18, 20, 25])

        XCTAssertEqual(comparisons.map(\.percentage), [15, 18, 20, 25])
        XCTAssertEqual(comparisons.count, 4)
    }

    func test_tipComparisons_withServiceContextPresets_shouldUseActiveContext() {
        calculationViewModel.billAmount = 100
        calculationViewModel.numberOfPeople = 2
        calculationViewModel.serviceContext = .coffee

        let comparisons = calculationViewModel.tipComparisons(for: calculationViewModel.serviceContext.suggestedPresets)

        XCTAssertEqual(comparisons.map(\.percentage), [10, 15, 20])
    }

    func test_tipComparisons_withInvalidBill_shouldReturnNoRows() {
        calculationViewModel.billAmount = nil

        let comparisons = calculationViewModel.tipComparisons(for: [15, 18, 20, 25])

        XCTAssertTrue(comparisons.isEmpty)
    }

    func test_tipComparisons_roundTotalUp_shouldReflectRoundedTotal() throws {
        calculationViewModel.billAmount = 10
        calculationViewModel.numberOfPeople = 3
        calculationViewModel.roundingMode = .roundTotalUp

        let comparison = try XCTUnwrap(calculationViewModel.tipComparisons(for: [18]).first)

        XCTAssertEqual(comparison.tipAmount, 1.8, accuracy: 0.001)
        XCTAssertEqual(comparison.totalAmountWithTip, 12)
        XCTAssertEqual(comparison.totalPerPerson, 4)
    }

    func test_tipComparisons_roundPerPersonUp_shouldReflectCollectedTotal() throws {
        calculationViewModel.billAmount = 10
        calculationViewModel.numberOfPeople = 3
        calculationViewModel.roundingMode = .roundPerPersonUp

        let comparison = try XCTUnwrap(calculationViewModel.tipComparisons(for: [18]).first)

        XCTAssertEqual(comparison.totalPerPerson, 4)
        XCTAssertEqual(comparison.totalAmountWithTip, 12)
    }

    func test_applySavedTip_shouldRestoreSavedInputsAndResetRounding() throws {
        calculationViewModel.billAmount = 12
        calculationViewModel.tipPercentage = 25
        calculationViewModel.numberOfPeople = 4
        calculationViewModel.roundingMode = .roundPerPersonUp
        calculationViewModel.tipItemName = "Current"

        let savedTip = try makeSavedTip(billAmount: 84.50, tipPercentage: 20, numberOfPeople: 3)

        calculationViewModel.applySavedTip(savedTip)

        XCTAssertEqual(calculationViewModel.billAmount, 84.50)
        XCTAssertEqual(calculationViewModel.tipPercentage, 20)
        XCTAssertEqual(calculationViewModel.numberOfPeople, 3)
        XCTAssertEqual(calculationViewModel.roundingMode, .none)
        XCTAssertEqual(calculationViewModel.tipItemName, "")
    }

    func test_applySavedTip_withOutOfRangeValues_shouldClampDefensively() throws {
        let savedTip = try makeSavedTip(billAmount: 40, tipPercentage: 45, numberOfPeople: 0)

        calculationViewModel.applySavedTip(savedTip)

        XCTAssertEqual(calculationViewModel.billAmount, 40)
        XCTAssertEqual(calculationViewModel.tipPercentage, 30)
        XCTAssertEqual(calculationViewModel.numberOfPeople, 1)
    }

    private func makeSavedTip(billAmount: Double, tipPercentage: Double, numberOfPeople: Int64) throws -> SavedTip {
        let container = NSPersistentContainer(name: "SavedTip")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let loadError {
            throw loadError
        }

        let savedTip = SavedTip(context: container.viewContext)
        savedTip.billAmount = billAmount
        savedTip.tipPercentage = tipPercentage
        savedTip.numberOfPeople = numberOfPeople
        savedTip.tipAmount = billAmount / 100 * tipPercentage
        savedTip.totalAmountWithTip = billAmount + savedTip.tipAmount
        savedTip.totalPerPerson = savedTip.totalAmountWithTip / Double(max(numberOfPeople, 1))
        savedTip.name = "Reusable Tip"
        savedTip.date = Date()
        savedTipContainers.append(container)
        return savedTip
    }

}
