//
//  NSManagedObject+Ex.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData
import Combine

// MARK: - Save - API
extension NSManagedObject {

    /// Saving changes to the database. Saving is done synchronously
    @discardableResult
    public func saveСhangesSync() -> Result<Void, SafeCoreDataError> {
        guard let context = self.managedObjectContext else {
            return .failure(SafeCoreDataError.failGetContext)
        }
        return context.saveSync()
    }

    /// Saving changes to the database. Saving is done asynchronously
    /// - Parameters:
    ///   - sucsess: This block is called when the save operation was successful
    ///   - failure: This block is called when a save operation has failed
    public func saveСhangesAsync(sucsess: (() -> Void)? = nil, failure: ((SafeCoreDataError) -> Void)? = nil) {
        guard let context = self.managedObjectContext else {
            failure?(SafeCoreDataError.failGetContext)
            return
        }

        context.saveAsync(completion: { saveEvent in
            switch saveEvent {
            case .success: sucsess?()
            case .failure: failure?(SafeCoreDataError.failSave)
            }
        })
    }

    /// Saving changes to the database. Saving is done asynchronously
    @discardableResult
    public func saveСhanges() async -> Result<Void, SafeCoreDataError> {
        guard let context = self.managedObjectContext else {
            return .failure(SafeCoreDataError.failGetContext)
        }

        return await withCheckedContinuation { checkedContinuation in
            context.saveAsync(completion: { saveEvent in
                switch saveEvent {
                case .success:
                    checkedContinuation.resume(returning: .success(()))

                case .failure:
                    checkedContinuation.resume(returning: .failure(SafeCoreDataError.failSave))
                }
            })
        }
    }

    /// Saving changes to the database. Saving is done asynchronously
    public func saveСhangesFeature() -> AnyPublisher<Void, SafeCoreDataError> {
        return Deferred {
            Future<Void, SafeCoreDataError> { promise in
                guard let context = self.managedObjectContext else {
                    promise(.failure(SafeCoreDataError.failGetContext))
                    return
                }

                context.saveAsync(completion: { saveEvent in
                    switch saveEvent {
                    case .success:
                        promise(.success(()))

                    case .failure:
                        promise(.failure(SafeCoreDataError.failSave))
                    }
                })
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Remove - API
extension NSManagedObject {

    /// Deletion from to the database. Deletion is done synchronously
    @discardableResult
    public func deleteSync() -> Result<Void, SafeCoreDataError> {
        guard let context = self.managedObjectContext else {
            return .failure(SafeCoreDataError.failGetContext)
        }

        var event: Result<Void, SafeCoreDataError> = .success(())
        context.performAndWait {
            context.delete(self)
            event = context.saveSync()
        }
        return event
    }

    /// Deletion from to the database. Deletion is done asynchronously
    /// - Parameters:
    ///   - sucsess: This block is called when the delete operation was successful
    ///   - failure: This block is called when a delete operation has failed
    public func deleteAsync(sucsess: (() -> Void)? = nil, failure: ((SafeCoreDataError) -> Void)? = nil) {
        guard let context = self.managedObjectContext else {
            failure?(SafeCoreDataError.failGetContext)
            return
        }

        context.perform {
            context.delete(self)
            let saveEvent = context.saveSync()
            switch saveEvent {
            case .success: sucsess?()
            case .failure: failure?(SafeCoreDataError.failSave)
            }
        }
    }

    /// Deletion from to the database. Deletion is done asynchronously
    @discardableResult
    public func delete() async -> Result<Void, SafeCoreDataError> {
        guard let context = self.managedObjectContext else {
            return .failure(SafeCoreDataError.failGetContext)
        }

        return await withCheckedContinuation { checkedContinuation in
            context.perform {
                context.delete(self)
                let saveEvent = context.saveSync()

                switch saveEvent {
                case .success:
                    checkedContinuation.resume(returning: .success(()))

                case .failure:
                    checkedContinuation.resume(returning: .failure(SafeCoreDataError.failSave))
                }
            }
        }
    }

    /// Deletion from to the database. Deletion is done asynchronously
    public func deleteFeature() -> AnyPublisher<Void, SafeCoreDataError> {
        return Deferred {
            Future<Void, SafeCoreDataError> { promise in
                guard let context = self.managedObjectContext else {
                    promise(.failure(SafeCoreDataError.failGetContext))
                    return
                }

                context.perform {
                    context.delete(self)
                    let saveEvent = context.saveSync()

                    switch saveEvent {
                    case .success:
                        promise(.success(()))

                    case .failure:
                        promise(.failure(SafeCoreDataError.failSave))
                    }
                }
            }
        }.eraseToAnyPublisher()
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

    /// Creates synchronously an entity in the same context as the object itself
    /// - Parameters:
    ///   - updateProperties: Block where you can override entity properties before saving to the database
    public func createChildObject<T: NSManagedObject>(withType: T.Type, updateProperties: (T) -> Void) -> T? {
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
