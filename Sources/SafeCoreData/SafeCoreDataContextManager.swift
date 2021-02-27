//
//  SafeCoreDataContextManager.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

class SafeCoreDataMainContext {
    fileprivate(set) static var mainObjectContexts: [Int: NSManagedObjectContext] = [:]
    static let safeMutex = DispatchSemaphore(value: 1)
    static let safeGlobalAsynQueue = DispatchQueue.global()
    private init() {}
}

class SafeCoreDataContextManager {

    // MARK: Private attirbute

    private let databaseConfig: SafeCoreData.Configuration.DataBase

    private var mainContext: NSManagedObjectContext {
        let index = databaseConfig.hashValue
        if let context = SafeCoreDataMainContext.mainObjectContexts[index] {
            return context
        }
        if let context = SafeCoreDataMainContext.mainObjectContexts[index] {
            return context
        }
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.performAndWait {
            context.persistentStoreCoordinator = self.createCoordinator()
        }

        SafeCoreDataMainContext.mainObjectContexts[index] = context
        return context
    }

    // MARK: Life cycle

    init(config: SafeCoreData.Configuration.DataBase) throws {
        self.databaseConfig = config

        // Attempts to find the database path; if the database does not find, it stops at initialization
        _ = try createModel()

        // initializes context. If this is not done then with a large scope of tasks the first time you work with the context, the application may crash
        _ = getMainContext()
    }

}

// MARK: - API
extension SafeCoreDataContextManager {

    /// Getting main context for the specified Database.
    /// The mainQueueConcurrencyType concurrency type associates the managed object context with the main queue.
    /// This is important if the managed object context is used in conjunction with view controllers or is linked
    /// to the application's user interface.
    func getMainContext() -> NSManagedObjectContext {
        return mainContext
    }

    /// Getting private context for the specified Database.
    /// All the write operations will be done in the context which is of PrivateConcurrencyType. After the data state
    /// is passed to the parent context
    func createPrivateContext() -> NSManagedObjectContext {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.performAndWait {
            privateContext.parent = self.mainContext
        }
        return privateContext
    }

}

// MARK: - Private operations
private extension SafeCoreDataContextManager {

    ///
    private func createCoordinator() -> NSPersistentStoreCoordinator {
        guard let model = try? self.createModel() else {
            // The designer checks that the model is being created, here the object should always be created
            fatalError()
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStore(ofType: databaseConfig.persistentType,
                                               configurationName: nil,
                                               at: self.getUrlDataBase(),
                                               options: databaseConfig.persistentOptions)
            return coordinator
        } catch {
            let errorMessage = "Error Persistent store! \(error)"
            NSLog(errorMessage)
            fatalError(errorMessage)
        }
    }

    /// Gets the path where the database is located
    private func getUrlDataBase() -> URL {
        let documentsDirectoryURL = FileManager.default.urls(for: databaseConfig.pathDirectory, in: .userDomainMask)[0]
        let url = documentsDirectoryURL.appendingPathComponent(databaseConfig.fileName)

        for type in databaseConfig.printTypes {
            guard case .pathCoreData(let prefix, let postfix) = type else { continue }
            let message = (prefix ?? "") + "\(url)" + (postfix ?? "")
            print(message)
        }

        return url
    }

    /// Creates a database model
    private func createModel() throws -> NSManagedObjectModel {
        guard let modelURL = getModelURL(),
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw SafeCoreDataError.noDataBaseModel
        }
        return model
    }

    private func getModelURL() -> URL? {
        let modelName: String
        let urlExtension: String
        if let version = databaseConfig.modelVersion {
            modelName = "\(databaseConfig.modelName).momd/\(databaseConfig.modelName) \(version)"
            urlExtension = "mom"
        } else {
            modelName = databaseConfig.modelName
            urlExtension = "momd"
        }

        if let mainUrl = Bundle.main.url(forResource: modelName, withExtension: urlExtension) {
            return mainUrl
        }
        var bandles = Bundle.allFrameworks
        Bundle.allBundles.forEach { bandles.append($0) }

        return bandles
            .first(where: { $0.bundleIdentifier == self.databaseConfig.bundleIdentifier })?
            .url(forResource: modelName, withExtension: urlExtension)
    }

}
