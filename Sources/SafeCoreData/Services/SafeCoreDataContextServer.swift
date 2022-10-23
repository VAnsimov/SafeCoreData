//
//  SafeCoreDataContextServer.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

class SafeCoreDataContextServer {

    // MARK: Private attirbute

    private static var mainObjectContexts: [Int: NSManagedObjectContext] = [:]

    private let databaseConfig: SafeCoreData.DataBase.Configuration

    private var mainContext: NSManagedObjectContext {
        let index = databaseConfig.hashValue
        if let context = Self.mainObjectContexts[index] {
            return context
        }
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.performAndWait {
            context.persistentStoreCoordinator = self.createCoordinator()
        }

        Self.mainObjectContexts[index] = context
        return context
    }

    // MARK: Life cycle

    init(config: SafeCoreData.DataBase.Configuration) throws {
        self.databaseConfig = config

        // Attempts to find the database path; if the database does not find, it stops at initialization
        _ = try createModel()

        // initializes context. If this is not done then with a large scope of tasks the first time you work with the context, the application may crash
        _ = getMainContext()
    }

}

// MARK: - API
extension SafeCoreDataContextServer {

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
private extension SafeCoreDataContextServer {

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

        let bandle: Bundle?

        switch databaseConfig.bundleType {
        case let .bundle(data):
            bandle = data

        case let .identifier(bundleIdentifier):
            let bandles = [Bundle.main] + Bundle.allFrameworks + Bundle.allBundles

            bandle = bandles.first(where: { $0.bundleIdentifier == bundleIdentifier })
        }

        return bandle?.url(forResource: modelName, withExtension: urlExtension)
    }
}
