//
//  SafeCoreDataService+Fetch.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Fetch API
extension SafeCoreDataService {

    /// Search and retrieve entities from the database
    /// - Parameters:
    ///   - withType: The type of entity to be fetch.
    ///   - configure: Entity fetch process configuration
    ///   - completion: Called when the was successful, returns the result found OR when something went wrong
    public func fetch<T: NSManagedObject>(
        withType: T.Type,
        configure: SafeCoreData.Fetch.Configuration = .init(),
        completion: @escaping (SafeCoreData.ResultData<[T]>) -> Void
    ) {
        let fetchRequest: NSFetchRequest<T> = creatFetchRequest(configure: configure)
        let privateContext = contextManager.createPrivateContext()

        privateContext.perform {
            do {
                let fetchResult = try privateContext.fetch(fetchRequest)
                let result = SafeCoreData.ResultData<[T]>(result: .success(fetchResult), context: privateContext)

                configure.outputThread.action {
                    completion(result)
                }
            } catch let error {
                let result = SafeCoreData.ResultData<[T]>(
                    result: .failure(.failFetchComponent(message: error.localizedDescription)),
                    context: privateContext)

                configure.outputThread.action {
                    completion(result)
                }
            }
        }
    }

    /// Search and retrieve entities from the database
    /// - Parameters:
    ///   - withType: The type of entity to be fetch.
    ///   - configure: Entity fetch process configuration
    public func fetchSync<T: NSManagedObject>(
        withType: T.Type,
        configure: SafeCoreData.Fetch.ConfigurationSync = .init()
    ) -> SafeCoreData.ResultData<[T]> {
        let fetchRequest: NSFetchRequest<T> = creatFetchRequest(configure: configure)
        let privateContext = contextManager.createPrivateContext()

        var result: SafeCoreData.ResultData<[T]> = .init(result: .failure(.failFetchComponent(message: "nil")),
                                                         context: privateContext)

        privateContext.performAndWait {
            do {
                let data = try privateContext.fetch(fetchRequest)
                result = .init(result: .success(data),
                               context: privateContext)
            } catch let error {
                result = .init(result: .failure(.failFetchComponent(message: error.localizedDescription)),
                               context: privateContext)
            }
        }

        return result
    }
}

// MARK: - Private operation
private extension SafeCoreDataService {

    func creatFetchRequest<T>(configure: SafeCoreData.Fetch.ConfigurationSync) -> NSFetchRequest<T> {
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
