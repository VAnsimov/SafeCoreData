//
//  SafeCoreDataService+Remove.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Fetch API
extension SafeCoreDataService {

    public var withRemoveParameters: SafeCoreData.Service.Remove {
        SafeCoreData.Service.Remove(dataStorage: self)
    }

    /// Search and removed entities from the database
    /// - Parameters:
    ///   - withType: The type of entity to be remove.
    ///   - configure: Entity remove process configuration
    ///   - success: Called when the remove was successful, Returns id of deleted objects
    ///   - failure: Called when something went wrong
    func remove<T: NSManagedObject>(
        withType: T.Type,
        configure: SafeCoreData.Remove.Configuration = .init(),
        success: (([NSManagedObjectID]) -> Void)? = nil,
        failure: ((SafeCoreDataError) -> Void)? = nil
    ) {
        remove(withType: withType, configure: configure, completion: { result in
            switch result.resultType {
            case let .success(objects):
                success?(objects)

            case let .failure(error):
                failure?(error)
            }
        })
    }

    /// Search and removed entities from the database
    /// - Parameters:
    ///   - withType: The type of entity to be remove
    ///   - configure: Entity remove process configuration
    ///   - completion:  Called when the remove was successful, returns the result found OR when something went wrong
    func remove<T: NSManagedObject>(
        withType: T.Type,
        configure: SafeCoreData.Remove.Configuration = .init(),
        completion: ((SafeCoreData.ResultData<[NSManagedObjectID]>) -> Void)? = nil
    ) {
        let fetchRequest = creatFetchRequest(entityName: String(describing: T.self),
                                                  withPredicate: configure.filter)
        let deleteRequest = createBatchDeleteRequest(fetchRequest: fetchRequest)
        let privateContext = contextManager.createPrivateContext()

        privateContext.perform {
            let persistentStoreResult = try? privateContext.execute(deleteRequest)
            guard let batchDeleteResult = persistentStoreResult as? NSBatchDeleteResult else {
                let result = SafeCoreData.ResultData<[NSManagedObjectID]>(result: .failure(.failRemove),
                                                                          context: privateContext)

                configure.outputThread.action {
                    completion?(result)
                }
                return
            }

            let deletedObjects = (batchDeleteResult.result as? [NSManagedObjectID]) ?? []

            let result = SafeCoreData.ResultData<[NSManagedObjectID]>(result: .success(deletedObjects),
                                                                      context: privateContext)

            configure.outputThread.action {
                completion?(result)
            }
        }
    }

    /// Search and removed entities from the database
    /// - Parameters:
    ///   - type: The type of entity to be remove.
    ///   - config: Entity remove process configuration
    @discardableResult
    func removeSync<T: NSManagedObject>(
        withType: T.Type,
        configure: SafeCoreData.Remove.ConfigurationSync = .init()
    ) -> SafeCoreData.ResultData<[NSManagedObjectID]> {
        let fetchRequest = creatFetchRequest(entityName: String(describing: T.self),
                                             withPredicate: configure.filter)
        let deleteRequest = createBatchDeleteRequest(fetchRequest: fetchRequest)
        let privateContext = contextManager.createPrivateContext()

        var result: SafeCoreData.ResultData<[NSManagedObjectID]> = .init(result: .failure(.failRemove),
                                                                         context: privateContext)

        privateContext.performAndWait {
            let persistentStoreResult = try? privateContext.execute(deleteRequest)

            guard let batchDeleteResult = persistentStoreResult as? NSBatchDeleteResult else {
                result = .init(result: .failure(.failRemove), context: privateContext)
                return
            }

            let deletedObjects = (batchDeleteResult.result as? [NSManagedObjectID]) ?? []
            result = .init(result: .success(deletedObjects),context: privateContext)
        }

        return result
    }
}

// MARK: - Private operation

private extension SafeCoreDataService {

    func creatFetchRequest(entityName: String,
                                   withPredicate: NSPredicate?) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

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
