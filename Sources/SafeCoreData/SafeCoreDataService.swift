//
//  SafeCoreDataService.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

open class SafeCoreDataService {

    let contextManager: SafeCoreDataContextServer

    // MARK: Init

    /// Quick initialization with default settings. The SafeCoreDataService has a link to its internal database, you can also specify which database the SafeCoreDataService will link to.SafeCoreDataService works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
    /// - Parameters:
    ///   - databaseName: File name  *.xcdatamodeld
    ///   - bundleIdentifier: The receiver’s bundle identifier.
    public init(databaseName: String, bundleIdentifier: String) throws {
        let storageConfig = SafeCoreData.DataBase.Configuration(modelName: databaseName,
                                                                bundleType: .identifier(bundleIdentifier))
        let storageContextManager = try SafeCoreDataContextServer(config: storageConfig)
        self.contextManager = storageContextManager
    }

    /// Quick initialization with default settings. The SafeCoreDataService has a link to its internal database, you can also specify which database the SafeCoreDataService will link to.SafeCoreDataService works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
    /// - Parameters:
    ///   - databaseName: File name  *.xcdatamodeld
    ///   - bundle: The receiver’s bundle.
    public init(databaseName: String, bundle: Bundle) throws {
        let storageConfig = SafeCoreData.DataBase.Configuration(modelName: databaseName,
                                                                bundleType: .bundle(bundle))
        let storageContextManager = try SafeCoreDataContextServer(config: storageConfig)
        self.contextManager = storageContextManager
    }

    /// The SafeCoreData has a link to its internal database, you can also specify which database the SafeCoreDataService will link to.SafeCoreDataService works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
    /// - Parameters:
    ///    - database: Customization of Coredata
    public init(database: SafeCoreData.DataBase.Configuration) throws {
        let storageContextManager = try SafeCoreDataContextServer(config: database)
        self.contextManager = storageContextManager
    }
}
