//
//  SafeCoreData+Remove.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Fetch API
extension SafeCoreData {

    /// Search and removed entities from the database
    /// - Parameters:
    ///   - type: The type of entity to be remove.
    ///   - config: Entity remove process configuration
    ///   - success: Called when the save was successful, Returns id of deleted objects
    ///   - fail: Called when something went wrong
    public func remove<T: NSManagedObject>(type: T.Type,
                                           configure: Configuration.Remove = Configuration.Remove(),
                                           success: (([NSManagedObjectID]) -> Void)? = nil,
                                           fail: ((SafeCoreDataError) -> Void)? = nil) {
        let fetchRequest = self.creatFetchRequest(entityName: String(describing: T.self),
                                                  withPredicate: configure.filter)
        let deleteRequest = self.createBatchDeleteRequest(fetchRequest: fetchRequest)
        let privateContext = contextManager.createPrivateContext()

        privateContext.perform(inThread: configure.concurrency, actionBlock: { context in
            let persistentStoreResult = try? context.execute(deleteRequest)
            guard let batchDeleteResult = persistentStoreResult as? NSBatchDeleteResult else {
                fail?(SafeCoreDataError.failRemove)
                return
            }

            let deletedObjects = (batchDeleteResult.result as? [NSManagedObjectID]) ?? []
            success?(deletedObjects)
        })
    }

}

// MARK: - Private operation
private extension SafeCoreData {

    private func creatFetchRequest(entityName: String,
                                   withPredicate: NSPredicate?) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

        //
        fetchRequest.fetchBatchSize = 20
        fetchRequest.predicate = withPredicate

        return fetchRequest
    }

    private func createBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> NSBatchDeleteRequest {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        return deleteRequest
    }

}
