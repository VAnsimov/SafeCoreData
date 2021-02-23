//
//  SafeCoreData.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

open class SafeCoreData {

    let contextManager: SafeCoreDataContextManager

    // MARK: Init

    /// Quick initialization with default settings. The SafeCoreData has a link to its internal database, you can also specify which database the SafeCoreData will link to.SafeCoreData works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
    /// - Parameters:
    ///   - databaseName: File name  *.xcdatamodeld
    ///   - bundleIdentifier: The receiver’s bundle identifier.
    public init?(databaseName: String, bundleIdentifier: String) {
        let storageConfig = Configuration.DataBase(modelName: databaseName, bundleIdentifier: bundleIdentifier)
        guard let storageContextManager = try? SafeCoreDataContextManager(config: storageConfig) else {
            return nil
        }
        self.contextManager = storageContextManager
    }

    /// The SafeCoreData has a link to its internal database, you can also specify which database the SafeCoreData will link to.SafeCoreData works with the Coredata database, receive, retrieve, update entities. Quick initialization with default settings
    /// - Parameters:
    ///    - database: Customization of Coredata
    public init?(database: SafeCoreData.Configuration.DataBase) {
        guard let storageContextManager = try? SafeCoreDataContextManager(config: database) else {
            return nil
        }
        self.contextManager = storageContextManager
    }
}
