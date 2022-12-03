//
//  NSManagedObjectContext+Ex.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Save
extension NSManagedObjectContext {

    @discardableResult
    public func saveSync() -> Result<Void, SafeCoreDataError> {
        var result: Result<Void, SafeCoreDataError> = .failure(.failSave)

        self.performAndWait {
            result = self.saveThrows()
        }

        guard let parentContext = self.parent else {
            return result
        }
        parentContext.performAndWait {
            result = parentContext.saveThrows()
        }
        return result
    }

    public func saveAsync(completion: @escaping (Result<Void, SafeCoreDataError>) -> Void) {
        self.perform {
            var saveEvent = self.saveThrows()
            switch saveEvent {
            case .success:
                guard let parentContext = self.parent else {
                    completion(.success(()))
                    return
                }
                parentContext.performAndWait {
                    saveEvent = parentContext.saveThrows()
                }
                completion(saveEvent)
                
            case .failure:
                completion(saveEvent)
            }
        }
    }

    @discardableResult
    private func saveThrows() -> Result<Void, SafeCoreDataError> {
        guard self.hasChanges else {
            return .success(())
        }

        do {
            try self.save()
            return .success(())
        } catch let error {
            return .failure(SafeCoreDataError.save(error: error))
        }
    }

}
