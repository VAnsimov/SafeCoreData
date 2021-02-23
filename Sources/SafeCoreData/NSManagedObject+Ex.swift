//
//  NSManagedObject+Ex.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Save - API
extension NSManagedObject {

    /// Saving changes to the database. Saving is done synchronously
    @discardableResult
    public func saveСhangesSync() -> NSManagedObjectContext.OperationResult {
        guard let context = self.managedObjectContext else {
            return .error(SafeCoreDataError.failGetContext)
        }
        return context.saveSync()
    }

    /// Saving changes to the database. Saving is done asynchronously
    /// - Parameters:
    ///   - sucsess: This block is called when the save operation was successful
    ///   - fail: This block is called when a save operation has failed
    public func saveСhangesAsync(sucsess: (() -> Void)? = nil, fail: ((SafeCoreDataError) -> Void)? = nil) {
        guard let context = self.managedObjectContext else {
            fail?(SafeCoreDataError.failGetContext)
            return
        }

        context.saveAsync(completion: { saveEvent in
            switch saveEvent {
            case .success: sucsess?()
            case .error: fail?(SafeCoreDataError.failSave)
            }
        })
    }

}

// MARK: - Remove - API
extension NSManagedObject {

    /// Deletion from to the database. Deletion is done synchronously
    @discardableResult
    public func deleteSync() -> NSManagedObjectContext.OperationResult {
        guard let context = self.managedObjectContext else {
            return .error(SafeCoreDataError.failGetContext)
        }

        var event: NSManagedObjectContext.OperationResult = .success
        context.performAndWait {
            context.delete(self)
            event = context.saveSync()
        }
        return event
    }

    /// Deletion from to the database. Deletion is done asynchronously
    /// - Parameters:
    ///   - sucsess: This block is called when the delete operation was successful
    ///   - fail: This block is called when a delete operation has failed
    public func deleteAsync(sucsess: (() -> Void)? = nil, fail: ((SafeCoreDataError) -> Void)? = nil) {
        guard let context = self.managedObjectContext else {
            fail?(SafeCoreDataError.failGetContext)
            return
        }

        context.perform {
            context.delete(self)
            let saveEvent = context.saveSync()
            switch saveEvent {
            case .success: sucsess?()
            case .error: fail?(SafeCoreDataError.failSave)
            }
        }
    }

}

// MARK: - Create - API
extension NSManagedObject {

    /// Creates synchronously an entity in the same context as the object itself
    /// - Parameters:
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    public func createChildObject<T: NSManagedObject>(updateProperties: (T) -> Void) -> T? {
        guard let context = self.managedObjectContext else { return nil }

        var object: T?
        context.performAndWait {
            guard let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: T.self),
                                                                     in: context) else { return }
            let newObject = T(entity: entityDescription, insertInto: context)
            updateProperties(newObject)
            object = newObject
        }

        return object
    }

}
