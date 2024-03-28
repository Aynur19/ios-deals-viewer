//
//  DealDto.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 26.03.2024.
//

import Foundation

struct DealDto: Identifiable {
    let id: Int64
    let dateModifier: Date
    let instrumentName: String
    let price: Double
    let amount: Double
    let side: Side

    enum Side: String, CaseIterable {
        case sell, buy
    }
    
    init(
        id: Int64,
        dateModifier: Date,
        instrumentName: String,
        price: Double,
        amount: Double,
        side: Side
    ) {
        self.id = id
        self.dateModifier = dateModifier
        self.instrumentName = instrumentName
        self.price = price
        self.amount = amount
        self.side = side
    }
}

extension DealDto {
    enum CodingKeys: String {
        case id
        case dateModifier
        case instrumentName
        case price
        case amount
        case side
    }
    
    var dictionaryValue: [String: Any] {
        [
            Deal.Properties.externalId.rawValue: id,
            Deal.Properties.updatedOn.rawValue: dateModifier,
            Deal.Properties.instrument.rawValue: instrumentName,
            Deal.Properties.price.rawValue: price,
            Deal.Properties.amount.rawValue: amount,
            Deal.Properties.side.rawValue: side.rawValue
        ]
    }
}
