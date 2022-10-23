//
//  SafeCoreData+Service+Remove.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import CoreData
import Combine

extension SafeCoreData.Service {
    public class Remove: SafeCoreData.Remove.Configuration {

        private let dataStorage: SafeCoreDataService

        /// Entity  fetch process configuration
        /// - Parameters:
        ///   - dataStorage: The SafeCoreDataService has a link to its internal database, you can also specify which database the SafeCoreDataService will link to.SafeCoreDataService works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
        public init(dataStorage: SafeCoreDataService) {
            self.dataStorage = dataStorage

            super.init()
        }

        /// Search and removed entities from the database
        /// - Parameters:
        ///   - withType: The type of entity to be remove
        ///   - failure: Called when something went wrong
        ///   - success: Called when the remove was successful, Returns id of deleted objects
        public func remove<T: NSManagedObject>(
            withType: T.Type,
            updateProperties: @escaping (T) -> Void,
            failure: ((SafeCoreDataError) -> Void)? = nil,
            success: (([NSManagedObjectID]) -> Void)? = nil
        ) {
            dataStorage.remove(
                withType: withType,
                configure: self,
                success: success,
                failure: failure)
        }

        /// Search and removed entities from the database
        /// - Parameters:
        ///   - type: The type of entity to be remove
        ///   - success: Called when the remove was successful, Returns id of deleted objects
        ///   - failure: Called when something went wrong
        public func remove<T: NSManagedObject>(
            withType: T.Type,
            success: (([NSManagedObjectID]) -> Void)? = nil,
            failure: ((SafeCoreDataError) -> Void)? = nil
        ) {
            dataStorage.remove(
                withType: withType,
                configure: self,
                success: success,
                failure: failure)
        }

        /// Search and removed entities from the database
        /// - Parameters:
        ///   - type: The type of entity to be remove.
        ///   - completion:  Called when the remove was successful, returns the result found OR when something went wrong
        public func remove<T: NSManagedObject>(
            withType: T.Type,
            completion: ((SafeCoreData.ResultData<[NSManagedObjectID]>) -> Void)?
        ) {
            dataStorage.remove(
                withType: withType,
                configure: self,
                completion: completion)
        }

        /// Search and removed entities from the database
        /// - Parameters:
        ///   - type: The type of entity to be remove.
        public func remove<T: NSManagedObject>(
            withType: T.Type
        ) async throws -> SafeCoreData.Service.Data<[NSManagedObjectID]> {
            try await withCheckedThrowingContinuation { checkedContinuation in
                dataStorage.remove(
                    withType: withType,
                    configure: self,
                    completion: { result in
                        switch result.resultType {
                        case let .success(object):
                            checkedContinuation.resume(returning: .init(value: object, context: result.context))

                        case let .failure(error):
                            checkedContinuation.resume(throwing: error)
                        }
                    })
            }
        }

        /// Search and removed entities from the database
        /// - Parameters:
        ///   - type: The type of entity to be remove.
        public func removeFuture<T: NSManagedObject>(
            withType: T.Type
        ) -> AnyPublisher<SafeCoreData.Service.Data<[NSManagedObjectID]>, SafeCoreDataError> {
            let configure: SafeCoreData.Remove.Configuration = self
            let dataStorage = dataStorage

            return Deferred {
                Future<SafeCoreData.Service.Data<[NSManagedObjectID]>, SafeCoreDataError> { promise in
                    dataStorage.remove(
                        withType: withType,
                        configure: configure,
                        completion: { result in
                            switch result.resultType {
                            case let .success(object):
                                promise(.success(.init(value: object, context: result.context)))

                            case let .failure(error):
                                promise(.failure(error))
                            }
                        })
                }
            }.eraseToAnyPublisher()
        }

        /// Search and removed entities from the database
        /// - Parameters:
        ///   - type: The type of entity to be remove
        public func removeSync<T: NSManagedObject>(
            withType: T.Type
        ) -> SafeCoreData.ResultData<[NSManagedObjectID]> {
            dataStorage.removeSync(
                withType: withType,
                configure: self)
        }
    }
}
