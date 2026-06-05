//
//  ContentViewModel.swift
//  Tippy
//
//  Created by Kabir Dhillon on 5/16/23.
//

import Foundation
import Combine
import SwiftUI

enum RoundingMode: String, CaseIterable {
    case none
    case roundTotalUp
    case roundPerPersonUp

    var title: String {
        switch self {
        case .none:
            return String(localized: "Exact")
        case .roundTotalUp:
            return String(localized: "Total Up")
        case .roundPerPersonUp:
            return String(localized: "Person Up")
        }
    }
}

enum TipTaxBasis: String, CaseIterable, Identifiable {
    case subtotalOnly
    case subtotalAndTax

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subtotalOnly:
            return String(localized: "Subtotal")
        case .subtotalAndTax:
            return String(localized: "Subtotal + Tax")
        }
    }
}

extension RoundingMode: Identifiable {
    nonisolated var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case green
    case blue
    case pink
    case orange
    case purple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .green:
            return String(localized: "Green")
        case .blue:
            return String(localized: "Blue")
        case .pink:
            return String(localized: "Pink")
        case .orange:
            return String(localized: "Orange")
        case .purple:
            return String(localized: "Purple")
        }
    }

    var accentColor: Color {
        switch self {
        case .green:
            return Color(red: 0.0, green: 0.537, blue: 0.263)
        case .blue:
            return Color(red: 0.0, green: 0.431, blue: 0.820)
        case .pink:
            return Color(red: 0.745, green: 0.118, blue: 0.384)
        case .orange:
            return Color(red: 0.741, green: 0.294, blue: 0.0)
        case .purple:
            return Color(red: 0.455, green: 0.220, blue: 0.753)
        }
    }
}

struct TipComparison: Identifiable, Equatable {
    let percentage: Double
    let tipAmount: Double
    let totalAmountWithTip: Double
    let totalPerPerson: Double

    var id: Double { percentage }
}

enum TipServiceContext: String, CaseIterable, Identifiable {
    case restaurant
    case bar
    case delivery
    case takeout
    case coffee
    case salon
    case barber
    case spa
    case nailSalon
    case petGroomer
    case rideshare
    case foodTruck
    case tourGuide
    case movers
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .restaurant:
            return String(localized: "Restaurant")
        case .bar:
            return String(localized: "Bar")
        case .delivery:
            return String(localized: "Delivery")
        case .takeout:
            return String(localized: "Takeout")
        case .coffee:
            return String(localized: "Coffee")
        case .salon:
            return String(localized: "Salon")
        case .barber:
            return String(localized: "Barber")
        case .spa:
            return String(localized: "Spa")
        case .nailSalon:
            return String(localized: "Nail Salon")
        case .petGroomer:
            return String(localized: "Pet Groomer")
        case .rideshare:
            return String(localized: "Rideshare")
        case .foodTruck:
            return String(localized: "Food Truck")
        case .tourGuide:
            return String(localized: "Tour Guide")
        case .movers:
            return String(localized: "Movers")
        case .custom:
            return String(localized: "Custom")
        }
    }

    var suggestedPresets: [Double] {
        switch self {
        case .restaurant, .custom:
            return [15, 18, 20, 25]
        case .bar, .delivery, .barber, .spa, .nailSalon, .petGroomer, .tourGuide:
            return [15, 18, 20]
        case .takeout:
            return [0, 10, 15]
        case .coffee:
            return [10, 15, 20]
        case .salon:
            return [15, 20, 25]
        case .rideshare, .foodTruck:
            return [10, 15, 18]
        case .movers:
            return [5, 10, 15]
        }
    }

    var systemImage: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .bar: return "wineglass"
        case .delivery: return "bicycle"
        case .takeout: return "bag"
        case .coffee: return "cup.and.saucer"
        case .salon: return "scissors"
        case .barber: return "scissors"
        case .spa: return "sparkles"
        case .nailSalon: return "paintbrush.pointed"
        case .petGroomer: return "pawprint"
        case .rideshare: return "car"
        case .foodTruck: return "truck.box"
        case .tourGuide: return "mappin.and.ellipse"
        case .movers: return "shippingbox"
        case .custom: return "slider.horizontal.3"
        }
    }

    var helperText: String {
        switch self {
        case .restaurant:
            return String(localized: "Common restaurant ranges are shown for full-service dining.")
        case .bar:
            return String(localized: "Bar presets work well for drinks and counter service.")
        case .delivery:
            return String(localized: "Delivery presets account for convenience and trip effort.")
        case .takeout:
            return String(localized: "Takeout often uses smaller optional tips.")
        case .coffee:
            return String(localized: "Coffee presets fit quick counter-service orders.")
        case .salon:
            return String(localized: "Salon presets reflect common personal-service ranges.")
        case .barber:
            return String(localized: "Barber presets fit haircut and grooming visits.")
        case .spa:
            return String(localized: "Spa presets fit personal care and wellness services.")
        case .nailSalon:
            return String(localized: "Nail salon presets fit common personal-service ranges.")
        case .petGroomer:
            return String(localized: "Pet grooming presets fit appointment-based care.")
        case .rideshare:
            return String(localized: "Rideshare presets are lighter than full-service dining.")
        case .foodTruck:
            return String(localized: "Food truck presets fit casual counter service.")
        case .tourGuide:
            return String(localized: "Tour guide presets fit guided experiences.")
        case .movers:
            return String(localized: "Movers presets stay modest for percentage-based estimates.")
        case .custom:
            return String(localized: "Use the standard presets or the slider for your own amount.")
        }
    }
}

@MainActor
final class TipSavvySettings: ObservableObject {
    @Published var defaultTipPercentage: Double {
        didSet {
            let clampedValue = Self.clampedTipPercentage(defaultTipPercentage)
            if defaultTipPercentage != clampedValue {
                defaultTipPercentage = clampedValue
                return
            }
            defaults.set(clampedValue, forKey: DefaultsKey.defaultTipPercentage)
        }
    }

    @Published var defaultNumberOfPeople: Int {
        didSet {
            let clampedValue = Self.clampedNumberOfPeople(defaultNumberOfPeople)
            if defaultNumberOfPeople != clampedValue {
                defaultNumberOfPeople = clampedValue
                return
            }
            defaults.set(clampedValue, forKey: DefaultsKey.defaultNumberOfPeople)
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: DefaultsKey.hapticsEnabled)
        }
    }

    @Published var selectedTheme: AppTheme {
        didSet {
            defaults.set(selectedTheme.rawValue, forKey: DefaultsKey.selectedTheme)
        }
    }

    let defaults: UserDefaults

    private enum DefaultsKey {
        static let defaultTipPercentage = "defaultTipPercentage"
        static let defaultNumberOfPeople = "defaultNumberOfPeople"
        static let hapticsEnabled = "hapticsEnabled"
        static let selectedTheme = "selectedTheme"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedTip = defaults.object(forKey: DefaultsKey.defaultTipPercentage) as? Double ?? 18
        defaultTipPercentage = Self.clampedTipPercentage(savedTip)

        let savedPeople = defaults.object(forKey: DefaultsKey.defaultNumberOfPeople) as? Int ?? 1
        defaultNumberOfPeople = Self.clampedNumberOfPeople(savedPeople)

        hapticsEnabled = defaults.object(forKey: DefaultsKey.hapticsEnabled) as? Bool ?? true

        let savedTheme = defaults.string(forKey: DefaultsKey.selectedTheme)
        selectedTheme = savedTheme.flatMap(AppTheme.init(rawValue:)) ?? .green
    }

    static func clampedTipPercentage(_ percentage: Double) -> Double {
        min(max(percentage, 0), 30)
    }

    static func clampedNumberOfPeople(_ people: Int) -> Int {
        min(max(people, 1), 99)
    }

    func resetPreferences() {
        defaultTipPercentage = 18
        defaultNumberOfPeople = 1
        hapticsEnabled = true
        selectedTheme = .green
    }
}

/// A view model responsible for managing bill information and calculating tip information.
@MainActor
final class CalculationViewModel: ObservableObject  {
    @Published var billAmount: Double?
    @Published var tipPercentage: Double
    @Published var numberOfPeople: Int
    @Published var roundingMode: RoundingMode
    @Published var serviceContext: TipServiceContext
    @Published var taxAmount: Double?
    @Published var tipTaxBasis: TipTaxBasis
    @Published var tipItemName = ""
    @Published var receiptNote = ""

    private let defaults: UserDefaults
    private let settings: TipSavvySettings?

    private enum DefaultsKey {
        static let tipPercentage = "tipPercentage"
        static let numberOfPeople = "numberOfPeople"
        static let roundingMode = "roundingMode"
        static let serviceContext = "serviceContext"
        static let tipTaxBasis = "tipTaxBasis"
    }

    init(defaults: UserDefaults = .standard, settings: TipSavvySettings? = nil) {
        self.defaults = defaults
        self.settings = settings

        let savedTip = defaults.object(forKey: DefaultsKey.tipPercentage) as? Double
        tipPercentage = Self.clampedTipPercentage(savedTip ?? settings?.defaultTipPercentage ?? 18)

        let savedPeople = defaults.object(forKey: DefaultsKey.numberOfPeople) as? Int ?? settings?.defaultNumberOfPeople ?? 1
        numberOfPeople = Self.clampedNumberOfPeople(savedPeople)

        let savedRoundingMode = defaults.string(forKey: DefaultsKey.roundingMode)
        roundingMode = savedRoundingMode.flatMap(RoundingMode.init(rawValue:)) ?? .none

        let savedServiceContext = defaults.string(forKey: DefaultsKey.serviceContext)
        serviceContext = savedServiceContext.flatMap(TipServiceContext.init(rawValue:)) ?? .restaurant

        let savedTipTaxBasis = defaults.string(forKey: DefaultsKey.tipTaxBasis)
        tipTaxBasis = savedTipTaxBasis.flatMap(TipTaxBasis.init(rawValue:)) ?? .subtotalOnly
    }

    var hasValidCalculation: Bool {
        guard let billAmount = billAmount else {
            return false
        }

        return billAmount > 0 && numberOfPeople >= 1 && taxValidationMessage == nil
    }

    var canSaveTip: Bool {
        hasValidCalculation && !tipItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var billValidationMessage: String? {
        guard let billAmount else {
            return String(localized: "Enter a bill amount to calculate totals.")
        }

        guard billAmount > 0 else {
            return String(localized: "Bill amount must be greater than zero.")
        }

        guard billAmount.isFinite else {
            return String(localized: "Bill amount must be a valid number.")
        }

        return nil
    }

    var taxValidationMessage: String? {
        guard let taxAmount else {
            return nil
        }

        guard taxAmount >= 0 else {
            return String(localized: "Tax must be zero or more.")
        }

        guard taxAmount.isFinite else {
            return String(localized: "Tax must be a valid number.")
        }

        return nil
    }

    var hasTax: Bool {
        sanitizedTaxAmount > 0
    }

    var sanitizedTaxAmount: Double {
        guard let taxAmount, taxAmount > 0 else {
            return 0
        }

        return Self.sanitizedAmount(taxAmount)
    }

    var subtotalAmount: Double {
        guard let billAmount else {
            return 0
        }

        return Self.sanitizedAmount(billAmount)
    }

    var billAmountWithTax: Double {
        Self.sanitizedAmount(subtotalAmount + sanitizedTaxAmount)
    }

    var tipBaseAmount: Double {
        switch tipTaxBasis {
        case .subtotalOnly:
            return subtotalAmount
        case .subtotalAndTax:
            return billAmountWithTax
        }
    }

    static func clampedTipPercentage(_ percentage: Double) -> Double {
        min(max(percentage, 0), 30)
    }

    static func clampedNumberOfPeople(_ people: Int) -> Int {
        min(max(people, 1), 99)
    }

    func persistSmartDefaults() {
        tipPercentage = Self.clampedTipPercentage(tipPercentage)
        numberOfPeople = Self.clampedNumberOfPeople(numberOfPeople)
        defaults.set(tipPercentage, forKey: DefaultsKey.tipPercentage)
        defaults.set(numberOfPeople, forKey: DefaultsKey.numberOfPeople)
        defaults.set(roundingMode.rawValue, forKey: DefaultsKey.roundingMode)
        defaults.set(serviceContext.rawValue, forKey: DefaultsKey.serviceContext)
        defaults.set(tipTaxBasis.rawValue, forKey: DefaultsKey.tipTaxBasis)
    }
    
    var tipAmount: Double {
        Self.sanitizedAmount(tipBaseAmount / 100 * tipPercentage)
    }
    
    var totalAmountWithTip: Double {
        switch roundingMode {
        case .none:
            return unroundedTotalAmountWithTip
        case .roundTotalUp:
            return unroundedTotalAmountWithTip.rounded(.up)
        case .roundPerPersonUp:
            guard numberOfPeople > 0 else {
                return 0
            }
            return totalPerPerson * Double(numberOfPeople)
        }
    }
    
    var totalPerPerson: Double {
        guard numberOfPeople > 0 else {
            return 0
        }

        let total = unroundedTotalAmountWithTip / Double(numberOfPeople)
        let roundedTotal: Double
        switch roundingMode {
        case .none, .roundTotalUp:
            roundedTotal = totalAmountForPeople / Double(numberOfPeople)
        case .roundPerPersonUp:
            roundedTotal = total.rounded(.up)
        }

        return Self.sanitizedAmount(roundedTotal)
    }

    var unroundedTotalForDisplay: Double {
        unroundedTotalAmountWithTip
    }

    var unroundedPerPersonForDisplay: Double {
        guard numberOfPeople > 0 else {
            return 0
        }

        return Self.sanitizedAmount(unroundedTotalAmountWithTip / Double(numberOfPeople))
    }

    func tipComparisons(for presets: [Double]) -> [TipComparison] {
        guard hasValidCalculation, let billAmount else {
            return []
        }

        return presets.map { preset in
            let tipAmount = billAmount / 100 * preset
            let unroundedTotal = Self.sanitizedAmount(billAmount + tipAmount)
            let totalPerPerson: Double
            let totalAmountWithTip: Double

            switch roundingMode {
            case .none:
                totalAmountWithTip = unroundedTotal
                totalPerPerson = Self.sanitizedAmount(unroundedTotal / Double(numberOfPeople))
            case .roundTotalUp:
                totalAmountWithTip = unroundedTotal.rounded(.up)
                totalPerPerson = Self.sanitizedAmount(totalAmountWithTip / Double(numberOfPeople))
            case .roundPerPersonUp:
                totalPerPerson = Self.sanitizedAmount((unroundedTotal / Double(numberOfPeople)).rounded(.up))
                totalAmountWithTip = totalPerPerson * Double(numberOfPeople)
            }

            return TipComparison(percentage: preset,
                                 tipAmount: Self.sanitizedAmount(tipAmount),
                                 totalAmountWithTip: Self.sanitizedAmount(totalAmountWithTip),
                                 totalPerPerson: totalPerPerson)
        }
    }

    private var unroundedTotalAmountWithTip: Double {
        Self.sanitizedAmount(billAmountWithTax + tipAmount)
    }

    private var totalAmountForPeople: Double {
        switch roundingMode {
        case .none:
            return unroundedTotalAmountWithTip
        case .roundTotalUp:
            return unroundedTotalAmountWithTip.rounded(.up)
        case .roundPerPersonUp:
            return unroundedTotalAmountWithTip
        }
    }

    private static func sanitizedAmount(_ amount: Double) -> Double {
        amount.isNaN || amount.isInfinite ? 0 : amount
    }

    func accessibilityTotalsSummary(currencyCode: String) -> String {
        var parts = [
            String(localized: "Subtotal") + ": " + Self.currencyString(billAmount ?? 0, currencyCode: currencyCode),
        ]
        if hasTax {
            parts.append(String(localized: "Tax") + ": " + Self.currencyString(sanitizedTaxAmount, currencyCode: currencyCode))
            parts.append(String(localized: "Tip Basis") + ": " + tipTaxBasis.title)
        }
        parts.append(String(localized: "Tip") + ": " + Self.currencyString(tipAmount, currencyCode: currencyCode))
        parts.append(String(localized: "Total With Tip") + ": " + Self.currencyString(totalAmountWithTip, currencyCode: currencyCode))
        parts.append(String(localized: "Total Per Person") + ": " + Self.currencyString(totalPerPerson, currencyCode: currencyCode))
        return parts.joined(separator: ", ")
    }

    private static func currencyString(_ amount: Double, currencyCode: String) -> String {
        amount.formatted(.currency(code: currencyCode))
    }
    
    /// Resets the tip calculation values.
    func resetValues() {
        billAmount = nil
        tipPercentage = settings?.defaultTipPercentage ?? 18
        numberOfPeople = settings?.defaultNumberOfPeople ?? 1
        roundingMode = .none
        serviceContext = .restaurant
        taxAmount = nil
        tipTaxBasis = .subtotalOnly
        tipItemName = ""
        receiptNote = ""
        persistSmartDefaults()
    }

    func applySettingsDefaults(defaultTipPercentage: Double? = nil, defaultNumberOfPeople: Int? = nil) {
        tipPercentage = defaultTipPercentage ?? settings?.defaultTipPercentage ?? tipPercentage
        numberOfPeople = defaultNumberOfPeople ?? settings?.defaultNumberOfPeople ?? numberOfPeople
        persistSmartDefaults()
    }

    func applySavedTip(_ savedTip: SavedTip) {
        billAmount = Self.sanitizedAmount(savedTip.billAmount)
        tipPercentage = Self.clampedTipPercentage(savedTip.tipPercentage)
        numberOfPeople = Self.clampedNumberOfPeople(Int(savedTip.numberOfPeople))
        roundingMode = .none
        taxAmount = savedTip.taxAmount?.doubleValue
        tipTaxBasis = (savedTip.tipsOnTax?.boolValue == true) ? .subtotalAndTax : .subtotalOnly
        tipItemName = ""
        receiptNote = savedTip.note ?? ""
        persistSmartDefaults()
    }
}

enum TipSavvyKeyboardField: Int, Hashable {
    case billAmount
    case taxAmount
}
