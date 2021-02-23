//
//  SafeCoreData+Fetch.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Fetch API
extension SafeCoreData {

    /// Search and retrieve entities from the database
    /// - Parameters:
    ///   - withType: The type of entity to be fetch.
    ///   - config: Entity fetch process configuration
    ///   - success: Called when the save was successful, returns the result found
    ///   - fail: Called when something went wrong
    open func fetch<T: NSManagedObject>(withType: T.Type,
                                        configure: Configuration.Fetch = Configuration.Fetch(),
                                        success: @escaping ([T]) -> Void,
                                        fail: ((SafeCoreDataError) -> Void)? = nil) {
        let fetchRequest: NSFetchRequest<T> = self.creatFetchRequest(configure: configure)
        let privateContext = contextManager.createPrivateContext()
        privateContext.perform(inThread: configure.concurrency, actionBlock: { context in
            do {
                let result = try context.fetch(fetchRequest)
                success(result)
            } catch let error {
                let message = "fail fetchAllComponents - \(error.localizedDescription)"
                NSLog(message)
                fail?(SafeCoreDataError.failFetchComponent(message: message))
            }
        })
    }

}

// MARK: - Private operation
private extension SafeCoreData {

    private func creatFetchRequest<T>(configure: Configuration.Fetch) -> NSFetchRequest<T> {
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>(entityName: String(describing: T.self))

        if let fetchLimit = configure.fetchLimit { fetchRequest.fetchLimit = fetchLimit }
        if let fetchBatchSize = configure.fetchBatchSize { fetchRequest.fetchBatchSize = fetchBatchSize }
        
        fetchRequest.fetchOffset = configure.fetchOffset
        fetchRequest.predicate = configure.filter
        fetchRequest.sortDescriptors = configure.sort
        fetchRequest.includesSubentities = configure.includesSubentities

        return fetchRequest
    }

}
