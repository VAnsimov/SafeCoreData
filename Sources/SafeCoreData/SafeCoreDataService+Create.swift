//
//  SafeCoreDataService+Create.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Create API
extension SafeCoreDataService {

    public var withCreateParameters: SafeCoreData.Service.Create {
        SafeCoreData.Service.Create(dataStorage: self)
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - configure: Entity creation process configuration
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - completion: Called when the save was successful, returns the result found OR when something went wrong
    func create<T: NSManagedObject>(
        withType: T.Type,
        configure: SafeCoreData.Create.Configuration = .init(),
        updateProperties: @escaping (T) -> Void,
        completion: ((SafeCoreData.ResultData<T>) -> Void)?
    ) {
        let privateContext = contextManager.createPrivateContext()

        privateContext.perform {
            // Creates new NSManagedObject
            guard let newObject: T = self.createNewObject(context: privateContext) else {
                let result = SafeCoreData.ResultData<T>(result: .failure(.failCreate), context: privateContext)

                configure.outputThread.action {
                    completion?(result)
                }
                return
            }

            // Updating entity properties
            updateProperties(newObject)

            // Save result
            let saveResult = privateContext.saveSync()

            switch saveResult {
            case .success:
                let result = SafeCoreData.ResultData<T>(result: .success(newObject), context: privateContext)

                configure.outputThread.action {
                    completion?(result)
                }
            case .failure:
                let result = SafeCoreData.ResultData<T>(result: .failure(.failSave), context: privateContext)
                configure.outputThread.action {
                    completion?(result)
                }
            }
        }
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - count: The number of objects to be created
    ///   - configure: Entity creation process configuration
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - completion: Called when the save was successful, returns the result found OR when something went wrong
    func create<T: NSManagedObject, L>(
        withType: T.Type,
        list: [L],
        configure: SafeCoreData.Create.Configuration = .init(),
        updateProperties: @escaping (L, T) -> Void,
        completion: ((SafeCoreData.ResultData<[T]>) -> Void)?
    ) {
        let privateContext = contextManager.createPrivateContext()

        privateContext.perform {
            var objects: [T] = []

            for item in list {
                // Creates new NSManagedObject
                guard let newObject: T = self.createNewObject(context: privateContext) else {
                    let result = SafeCoreData.ResultData<[T]>(result: .failure(.failCreate), context: privateContext)

                    configure.outputThread.action {
                        completion?(result)
                    }
                    return
                }

                // Updating entity properties
                updateProperties(item, newObject)

                objects.append(newObject)
            }

            // Save result
            let saveResult = privateContext.saveSync()

            switch saveResult {
            case .success:
                let result = SafeCoreData.ResultData<[T]>(result: .success(objects), context: privateContext)

                configure.outputThread.action {
                    completion?(result)
                }
            case .failure:
                let result = SafeCoreData.ResultData<[T]>(result: .failure(.failSave), context: privateContext)
                configure.outputThread.action {
                    completion?(result)
                }
            }
        }
    }

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - withType: The type of entity to be created
    ///   - configure: Entity creation process configuration
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    @discardableResult
    func createSync<T: NSManagedObject>(
        withType: T.Type,
        configure: SafeCoreData.Create.ConfigurationSync = .init(),
        updateProperties: @escaping (T) -> Void
    ) -> SafeCoreData.ResultData<T> {
        let privateContext = contextManager.createPrivateContext()
        var result: SafeCoreData.ResultData<T> = .init(result: .failure(.failCreate), context: privateContext)

        privateContext.performAndWait {
            // Creates new NSManagedObject
            guard let newObject: T = self.createNewObject(context: privateContext) else {
                result = .init(result: .failure(.failCreate), context: privateContext)
                return
            }
            
            // Updating entity properties
            updateProperties(newObject)
            
            // Save result
            let data = privateContext.saveSync()
            
            switch data {
            case .success: result = .init(result: .success(newObject), context: privateContext)
            case .failure: result = .init(result: .failure(.failSave), context: privateContext)
            }
        }

        return result
    }
}

// MARK: - Private operation
extension SafeCoreDataService {

	private func createNewObject<T: NSManagedObject>(context: NSManagedObjectContext) -> T? {
		let name = String(describing: T.self)
		guard let entityDescription = NSEntityDescription.entity(forEntityName: name, in: context) else { return nil }

        return T(entity: entityDescription, insertInto: context)
    }

}
