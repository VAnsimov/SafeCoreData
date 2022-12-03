//
//  SafeCoreData+Service+Fetch.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import CoreData
import Combine

extension SafeCoreData.Service {
    public class Fetch: SafeCoreData.Fetch.Configuration {

        private weak var dataStorage: SafeCoreDataService?
        private let contextManager: SafeCoreDataContextServer
        
        /// Entity  fetch process configuration
        /// - Parameters:
        ///   - dataStorage: The SafeCoreDataService has a link to its internal database, you can also specify which database the SafeCoreDataService will link to.SafeCoreDataService works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
        public init(dataStorage: SafeCoreDataService) {
            self.dataStorage = dataStorage
            self.contextManager = dataStorage.contextManager
            super.init()
        }

        /// Search and retrieve entities from the database
        /// - Parameters:
        ///   - withType: The type of entity to be fetch.
        ///   - failure: Called when something went wrong
        ///   - success: Called when the save was successful, returns the result found
        public func fetch<T: NSManagedObject>(
            withType: T.Type,
            failure: ((SafeCoreDataError) -> Void)? = nil,
            success: @escaping ([T]) -> Void
        ) {
            dataStorage?.fetch(withType: withType, configure: self, completion: { result in
                switch result.resultType {
                case let .success(objects):
                    success(objects)

                case let .failure(error):
                    failure?(error)
                }
            })
        }

        /// Search and retrieve entities from the database
        /// - Parameters:
        ///   - withType: The type of entity to be fetch.
        ///   - success: Called when the was successful, returns the result found
        ///   - failure: Called when something went wrong
        public func fetch<T: NSManagedObject>(
            withType: T.Type,
            success: @escaping ([T]) -> Void,
            failure: ((SafeCoreDataError) -> Void)? = nil
        ) {
            dataStorage?.fetch(withType: withType, configure: self, completion: { result in
                switch result.resultType {
                case let .success(objects):
                    success(objects)

                case let .failure(error):
                    failure?(error)
                }
            })
        }

        /// Search and retrieve entities from the database
        /// - Parameters:
        ///   - withType: The type of entity to be fetch.
        ///   - completion: Called when the was successful, returns the result found OR when something went wrong
        public func fetch<T: NSManagedObject>(
            withType: T.Type,
            completion: @escaping (SafeCoreData.ResultData<[T]>) -> Void
        ) {
            dataStorage?.fetch(
                withType: withType,
                configure: self,
                completion: completion)
        }

        /// Search and retrieve entities from the database
        /// - Parameters:
        ///   - withType: The type of entity to be fetch.
        /// - Warning: Do not refer to the data in the `try await`. In the example we will get empty data
        ///```swift
        ///let objects = try await safeCoreData
        ///    .withFetchParameters
        ///    .fetch(withType: NSManagedObjectType.self)
        ///    .value
        ///```
        public func fetch<T: NSManagedObject>(withType: T.Type) async throws -> SafeCoreData.Service.Data<[T]> {
            try await withCheckedThrowingContinuation { checkedContinuation in
                dataStorage?.fetch(
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

        /// Search and retrieve entities from the database
        /// - Parameters:
        ///   - withType: The type of entity to be fetch.
        public func fetchFuture<T: NSManagedObject>(
            withType: T.Type
        ) -> AnyPublisher<SafeCoreData.Service.Data<[T]>, SafeCoreDataError> {
            let configure: SafeCoreData.Fetch.Configuration = self
            let dataStorage = dataStorage

            return Deferred {
                Future<SafeCoreData.Service.Data<[T]>, SafeCoreDataError> { promise in
                    dataStorage?.fetch(
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

        /// Search and retrieve entities from the database
        /// - Parameters:
        ///   - withType: The type of entity to be fetch.
        public func fetchSync<T: NSManagedObject>(
            withType: T.Type
        ) -> SafeCoreData.ResultData<[T]> {
            dataStorage?.fetchSync(
                withType: withType,
                configure: self) ?? .init(
                    result: .failure(.noneSafeCoreDataService),
                    context: contextManager.createPrivateContext())
        }
    }
}
