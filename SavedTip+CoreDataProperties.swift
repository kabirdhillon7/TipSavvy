//
//  SavedTip+CoreDataProperties.swift
//  Tippy
//
//  Created by Kabir Dhillon on 6/11/23.
//
//

import Foundation
import CoreData


extension SavedTip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedTip> {
        return NSFetchRequest<SavedTip>(entityName: "SavedTip")
    }

    @NSManaged public var name: String?
    @NSManaged public var date: Date?
    @NSManaged public var billAmount: Double
    @NSManaged public var tipPercentage: Double
    @NSManaged public var numberOfPeople: Int64
    @NSManaged public var tipAmount: Double
    @NSManaged public var totalAmountWithTip: Double
    @NSManaged public var totalPerPerson: Double

}

extension SavedTip : Identifiable {

}
