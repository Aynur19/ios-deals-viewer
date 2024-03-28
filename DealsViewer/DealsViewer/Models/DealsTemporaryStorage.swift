//
//  DealsTemporaryStorage.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 28.03.2024.
//


final actor DealsTemporaryStorage {
    private var items = [DealDto]()
    
    var isEmpty: Bool { items.isEmpty }
    
    func addDealsDto(_ dtos: [DealDto]) {
        items.append(contentsOf: dtos)
    }
    
    func getItemsToSave() -> [DealDto] {
        let itemsToSave = items
        items.removeAll()
        
        return itemsToSave
    }
}
