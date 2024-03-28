//
//  DealViewDto.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 28.03.2024.
//

import Foundation

struct DealViewDto: Identifiable {
    let id: UUID
    let externalId: Int64
    let dateModifier: Date
    let instrumentName: String
    let price: Double
    let amount: Double
    let side: Side

    enum Side: String, CaseIterable {
        case sell, buy
        
        var str: String { rawValue.capitalized }
    }
    
    init(
        externalId: Int64,
        dateModifier: Date,
        instrumentName: String,
        price: Double,
        amount: Double,
        side: Side
    ) {
        self.id = UUID()
        self.externalId = externalId
        self.dateModifier = dateModifier
        self.instrumentName = instrumentName
        self.price = price
        self.amount = amount
        self.side = side
    }
    
    init(with deal: Deal) {
        id = UUID()
        externalId = deal.externalId
        dateModifier = deal.updatedOn!
        instrumentName = deal.instrument!
        price = deal.price
        amount = deal.amount
        side = .init(rawValue: deal.side!)!
    }
}

extension DealViewDto {
    enum CodingKeys: String {
        case id
        case externalId
        case dateModifier
        case instrumentName
        case price
        case amount
        case side
    }
    
    var instrumentStr: String { .init(instrumentName.split(separator: "_").first ?? "") }
        
    var priceStr: String { String(format: "%.2f", price) }
        
    var amountStr: String { NumberFormatter.localizedString(from: NSNumber(value: Int(amount)), number: .decimal) }
    
    var dictionaryValue: [String: Any] {
        [
            Deal.Properties.externalId.rawValue: externalId,
            Deal.Properties.updatedOn.rawValue: dateModifier,
            Deal.Properties.instrument.rawValue: instrumentName,
            Deal.Properties.price.rawValue: price,
            Deal.Properties.amount.rawValue: amount,
            Deal.Properties.side.rawValue: side.rawValue
        ]
    }
}
