//
//  DealsViewModel.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 27.03.2024.
//

import CoreData
import OSLog


final class DealsViewModel: ObservableObject {
    static let shared = DealsViewModel()
    
    @Published private(set) var dbRecordsCount = 0
    @Published private(set) var deals = [DealViewDto]()
    private var sortDescriptors = [SortKeyOrder(key: DealsSortKey.updatedOn.rawValue, ascending: true)]
    
    private let server = Server()
    private let storage = DealsTemporaryStorage()
    private let logger = Logger(subsystem: "com.aynur19.DealsViewer", category: "persistence")
    private let dbUpdateTimer: UInt64 = 2_000_000_000
    
    private let dataScreenCount = 20
    private var dataSelectOffset = 0
    private let dataSelectLimit = 600
    private let dataSelectBanch = 100
    
    private init() { }
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DealsDb")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.name = "viewContext"
        return container
    }()
    
    func updateSort(_ sortKey: DealsSortKey, isAsc: Bool) async {
        sortDescriptors[0] = .init(key: sortKey.rawValue, ascending: isAsc)
        
        await load()
    }
    
    private func isDatabaseExists() -> Bool {
        let fileManager = FileManager.default
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return false }
        
        logger.debug("CoreData database file location: \(storeURL)")
        return fileManager.fileExists(atPath: storeURL.path)
    }
    
    
    private func newTaskContext(operationName: String) -> NSManagedObjectContext {
        let taskContext = container.newBackgroundContext()
        taskContext.name = "\(operationName)Context"
        taskContext.transactionAuthor = "\(operationName)Deals"
        
        return taskContext
    }
    
    private var dataLoadingLowBound: Int {
        return dataSelectOffset + Int(Double(dataSelectLimit) * 0.2)
    }
    
    private var dataLoadingHighBound: Int {
        return dataSelectOffset + Int(Double(dataSelectLimit) * 0.8)
    }
    
    func loadDealsFromNetwork() async {
        server.subscribeToDeals { [weak self] items in
            guard let self = self, !items.isEmpty else { return }
            
            Task { await self.storage.addDealsDto(items) }
        }
        
        Task {
            while true {
                try await Task.sleep(nanoseconds: dbUpdateTimer)
                
                let dealsToSave = await storage.getItemsToSave()
                if dealsToSave.isEmpty { continue }
                logger.debug("Count of deals to save to the database: \(dealsToSave.count)")
                
                await loadFromNetwork(dealsToSave)
                
                let count = await getRecordsCount()
                let loadedData = await loadFromCoreDataDb()
                
                await MainActor.run {
                    updateViewData(count: count, loadedData: loadedData)
                }
            }
        }
    }
    
    private func updateViewData(count: Int, loadedData: [DealViewDto]) {
        dbRecordsCount = count
        
        var viewListCount = deals.count
        logger.info("Count of data before loading: \(viewListCount)")
        
        let removedCount = max(0, deals.count - dataSelectOffset)
        deals.removeLast(removedCount)
        deals.append(contentsOf: loadedData)
        
        viewListCount = deals.count
        logger.error("Count of data after loading: \(viewListCount)")
    }
    
    func load(height: CGFloat, yOffset: CGFloat) async {
        
        let bufferSize = yOffset + (height * 2)
        let coef = Int(bufferSize / height)
        let showedItemsCount = coef * dataScreenCount
        
        if dataSelectOffset == 0 && showedItemsCount < dataLoadingLowBound { return }
        if showedItemsCount > dataLoadingLowBound, showedItemsCount < dataLoadingHighBound { return }
        
        dataSelectOffset = max(0, showedItemsCount - dataSelectLimit / 2)
        print("reload()")
        
        await load()
    }
    
    private func load() async {
        let loadedData = await loadFromCoreDataDb()
        
        await MainActor.run {
            updateViewData(count: dbRecordsCount, loadedData: loadedData)
        }
    }
    
    private func loadFromCoreDataDb() async -> [DealViewDto] {
        let loadContext = newTaskContext(operationName: "load")
        
        let fetchRequest = Deal.fetchRequest()
        fetchRequest.sortDescriptors = sortDescriptors.compactMap { .init(key: $0.key, ascending: $0.ascending) }
        fetchRequest.fetchBatchSize = dataSelectBanch
        fetchRequest.fetchLimit = dataSelectLimit
        
        var loadedDeals = [DealViewDto]()
        
        do {
            loadedDeals = try loadContext.fetch(fetchRequest).compactMap { .init(with: $0) }
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        
        return loadedDeals//.compactMap { .init(with: $0) }
    }
    
    func deleteAll() async {
        let taskContext = newTaskContext(operationName: "deleteAll")
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Deal.name)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try taskContext.execute(batchDeleteRequest)
            try taskContext.save()
            
            logger.info("'Deal' entity table cleared!")
        } catch {
            logger.debug("\(error.localizedDescription)")
        }
        
        await MainActor.run {
            dbRecordsCount = 0
        }
    }
    
    private func loadFromNetwork(_ dtoList: [DealDto]) async {
        let networkLoadContext = newTaskContext(operationName: "saveNetwork")
        
        networkLoadContext.performAndWait {
            let batchInsertRequest = self.getDealsBatchInsertRequest(with: dtoList)
            
            if let fetchResult = try? networkLoadContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            
            self.logger.error("Failed to execute batch insert request.")
        }
    }
    
    private func getDealsBatchInsertRequest(with dtoList: [DealDto]) -> NSBatchInsertRequest {
        var index = 0
        let total = dtoList.count
        
        let batchInsertRequest = NSBatchInsertRequest(entity: Deal.entity()) { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: dtoList[index].dictionaryValue)
            index += 1
            return false
        }
        
        return batchInsertRequest
    }
    
    private func getRecordsCount() async -> Int {
        let taskContext = newTaskContext(operationName: "count")
        var count = 0
        
        do {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Deal.name)
            count = try taskContext.count(for: fetchRequest)
            
            logger.info("Count of records in CoreData database for \(Deal.name) entity: \(count)")
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        
        return count
    }
}
