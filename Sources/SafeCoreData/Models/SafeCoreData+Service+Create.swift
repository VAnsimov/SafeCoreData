//
//  SafeCoreData+Service+Create.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import CoreData
import Combine

extension SafeCoreData.Service {
    public class Create: SafeCoreData.Create.Configuration {

        private let dataStorage: SafeCoreDataService

        /// Entity  fetch process configuration
        /// - Parameters:
        ///   - dataStorage: The SafeCoreDataService has a link to its internal database, you can also specify which database the SafeCoreDataService will link to.SafeCoreDataService works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
        public init(dataStorage: SafeCoreDataService) {
            self.dataStorage = dataStorage
            super.init()
        }

    }
}

// MARK: - Create one object

extension SafeCoreData.Service.Create {

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created.
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - failure: Called when something went wrong
    ///   - success: Called when the save was successful, returns the created and saved entity
    public func createObject<T: NSManagedObject>(
        withType: T.Type,
        updateProperties: @escaping (T) -> Void,
        failure: ((SafeCoreDataError) -> Void)? = nil,
        success: ((T) -> Void)? = nil
    ) {
        dataStorage.create(
            withType: withType,
            configure: self,
            updateProperties: updateProperties,
            completion: { result in
                switch result.resultType {
                case let .success(objects):
                    success?(objects)

                case let .failure(error):
                    failure?(error)
                }
            })
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created.
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - success: Called when the save was successful, returns the created and saved entity
    ///   - failure: Called when something went wrong
    public func createObject<T: NSManagedObject>(
        withType: T.Type,
        updateProperties: @escaping (T) -> Void,
        success: ((T) -> Void)? = nil,
        failure: ((SafeCoreDataError) -> Void)? = nil
    ) {
        dataStorage.create(
            withType: withType,
            configure: self,
            updateProperties: updateProperties,
            completion: { result in
                switch result.resultType {
                case let .success(objects):
                    success?(objects)

                case let .failure(error):
                    failure?(error)
                }
            })
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - completion: Called when the save was successful, returns the result found OR when something went wrong
    public func createObject<T: NSManagedObject>(
        withType: T.Type,
        updateProperties: @escaping (T) -> Void,
        completion: ((SafeCoreData.ResultData<T>) -> Void)?
    ) {
        dataStorage.create(
            withType: withType,
            configure: self,
            updateProperties: updateProperties,
            completion: completion)
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - type: The type of entity to be created
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    public func createObject<T: NSManagedObject>(
        withType: T.Type,
        updateProperties: @escaping (T) -> Void
    ) async throws -> SafeCoreData.Service.Data<T> {
        try await withCheckedThrowingContinuation { checkedContinuation in
            dataStorage.create(
                withType: withType,
                configure: self,
                updateProperties: updateProperties,
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

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created.
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    public func createObjectFuture<T: NSManagedObject>(
        withType: T.Type,
        updateProperties: @escaping (T) -> Void
    ) -> AnyPublisher<SafeCoreData.Service.Data<T>, SafeCoreDataError> {
        let configure: SafeCoreData.Create.Configuration = self
        let dataStorage = dataStorage

        return Deferred {
            Future<SafeCoreData.Service.Data<T>, SafeCoreDataError> { promise in
                dataStorage.create(
                    withType: withType,
                    configure: configure,
                    updateProperties: updateProperties,
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

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - type: The type of entity to be created
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    public func createObjectSync<T: NSManagedObject>(
        withType: T.Type,
        updateProperties: @escaping (T) -> Void
    ) -> SafeCoreData.ResultData<T> {
        dataStorage.createSync(
            withType: withType,
            configure: self,
            updateProperties: updateProperties)
    }
}

// MARK: - Create list objects

extension SafeCoreData.Service.Create {

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - list: objects to be create
    ///   - configure: Entity creation process configuration
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - completion: Called when the save was successful, returns the result found OR when something went wrong
    public func createListOfObjects<T: NSManagedObject, L>(
        withType: T.Type,
        list: [L],
        configure: SafeCoreData.Create.Configuration = .init(),
        updateProperties: @escaping (L, T) -> Void,
        completion: ((SafeCoreData.ResultData<[T]>) -> Void)?
    ) {
        dataStorage.create(
            withType: withType,
            list: list,
            configure: self,
            updateProperties: updateProperties,
            completion: completion)
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - list: objects to be create
    ///   - configure: Entity creation process configuration
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - completion: Called when the save was successful, returns the result found OR when something went wrong
    public func createListOfObjects<T: NSManagedObject, L>(
        withType: T.Type,
        list: [L],
        configure: SafeCoreData.Create.Configuration = .init(),
        updateProperties: @escaping (L, T) -> Void,
        failure: ((SafeCoreDataError) -> Void)? = nil,
        success: (([T]) -> Void)? = nil
    ) {
        dataStorage.create(
            withType: withType,
            list: list,
            configure: self,
            updateProperties: updateProperties,
            completion: { result in
                switch result.resultType {
                case let .success(objects):
                    success?(objects)

                case let .failure(error):
                    failure?(error)
                }
            })
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - list: objects to be create
    ///   - configure: Entity creation process configuration
    public func createListOfObjects<T: NSManagedObject, L>(
        withType: T.Type,
        list: [L],
        configure: SafeCoreData.Create.Configuration = .init(),
        updateProperties: @escaping (L, T) -> Void
    ) async throws -> SafeCoreData.Service.Data<[T]> {
        try await withCheckedThrowingContinuation { checkedContinuation in
            dataStorage.create(
                withType: withType,
                list: list,
                configure: self,
                updateProperties: updateProperties,
                completion: { result in
                    switch result.resultType {
                    case let .success(objects):
                        checkedContinuation.resume(returning: .init(value: objects, context: result.context))

                    case let .failure(error):
                        checkedContinuation.resume(throwing: error)
                    }
                })
        }
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - list: objects to be create
    ///   - configure: Entity creation process configuration
    public func createListOfObjectsFuture<T: NSManagedObject, L>(
        withType: T.Type,
        list: [L],
        configure: SafeCoreData.Create.Configuration = .init(),
        updateProperties: @escaping (L, T) -> Void
    ) -> AnyPublisher<SafeCoreData.Service.Data<[T]>, SafeCoreDataError> {
        let configure: SafeCoreData.Create.Configuration = self
        let dataStorage = dataStorage

        return Deferred {
            Future<SafeCoreData.Service.Data<[T]>, SafeCoreDataError> { promise in
                dataStorage.create(
                    withType: withType,
                    list: list,
                    configure: configure,
                    updateProperties: updateProperties,
                    completion: { result in
                        switch result.resultType {
                        case let .success(objects):
                            promise(.success(.init(value: objects, context: result.context)))

                        case let .failure(error):
                            promise(.failure(error))
                        }
                    })
            }
        }.eraseToAnyPublisher()
    }
}
