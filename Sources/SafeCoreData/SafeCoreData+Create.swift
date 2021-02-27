//
//  SafeCoreData+Create.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Create API
extension SafeCoreData {

    /// Entity creation. Saves to the database
    /// - Parameters:
    ///   - type: The type of entity to be created.
    ///   - config: Entity creation process configuration
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    ///   - success: Called when the save was successful, returns the created and saved entity
    ///   - fail: Called when something went wrong
    public func create<T: NSManagedObject>(
        type: T.Type,
        configure: Configuration.Create = Configuration.Create(),
        updateProperties: @escaping (T) -> Void,
        success: ((T) -> Void)? = nil,
        fail: ((SafeCoreDataError) -> Void)? = nil
    ) {
        let privateContext = contextManager.createPrivateContext()
        privateContext.perform(inThread: configure.concurrency, actionBlock: { context in

            // Creates new NSManagedObject
            guard let newObject: T = self.createNewObject(context: context) else {
                fail?(SafeCoreDataError.failCreate)
                return
            }

            // Updating entity properties
            updateProperties(newObject)

            // Save result
            let result = context.saveSync()

            switch result {
            case .success: success?(newObject)
            case .error: fail?(SafeCoreDataError.failSave)
            }
        })
    }

}

// MARK: - Private operation
extension SafeCoreData {

    private func createNewObject<T: NSManagedObject>(context: NSManagedObjectContext) -> T? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: T.self),
                                                                 in: context)
            else {
                return nil
        }
        return T(entity: entityDescription, insertInto: context)
    }

}
