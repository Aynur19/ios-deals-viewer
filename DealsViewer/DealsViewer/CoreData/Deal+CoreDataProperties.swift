//
//  Deal+CoreDataProperties.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 26.03.2024.
//
//

import Foundation
import CoreData


extension Deal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Deal> {
        return NSFetchRequest<Deal>(entityName: Deal.name)
    }

    @NSManaged public var externalId: Int64
    @NSManaged public var updatedOn: Date?
    @NSManaged public var price: Double
    @NSManaged public var amount: Double
    @NSManaged public var side: String?
    @NSManaged public var instrument: String?

}

extension Deal : Identifiable {
    enum Properties: String {
        case externalId
        case updatedOn
        case price
        case amount
        case side
        case instrument
    }
}

extension Deal {
    static let name = "Deal"
}
