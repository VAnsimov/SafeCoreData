//
//  SafeCoreData.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import Foundation
import CoreData

public typealias SafeConfiguration = SafeCoreData.Configuration

extension SafeCoreData {
    public enum Configuration {}
}

// MARK: - DataBase

extension SafeCoreData.Configuration {
    
    ///  Database settings
    open class DataBase {

        public enum PrintType {
            case pathCoreData(prefix: String? = nil, postfix: String? = nil)
        }

        public enum PersistentType {
            case sqlLite
            case binary
            case memory
            case custom(value: String)

            fileprivate var value: String {
                switch self {
                case .sqlLite: return NSSQLiteStoreType
                case .binary: return NSBinaryStoreType
                case .memory: return NSInMemoryStoreType
                case let .custom(value): return value
                }
            }
        }

        let modelName: String
        let bundleIdentifier: String
        private(set) var persistentType: String
        private(set) var fileName: String
        private(set) var printTypes: [PrintType]
        private(set) var persistentOptions: [AnyHashable: Any]
        private(set) var pathDirectory: FileManager.SearchPathDirectory
        private(set) var modelVersion: Int?

        /// Database settings
        /// - Parameters:
        ///   - modelName: File name  *.xcdatamodeld
        ///   - bundleIdentifier: Project identifier where file .xcdatamodeld is located
        ///   - persistentType: A string constant (such as NSSQLiteStoreType) that specifies the store type
        ///   - persistentOptions: CoreData coordinator configuration. Default value is [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        ///   - pathDirectory: In which directory of the device will the database be located
        ///   - modelVersion: Version of the model database. 'nil' value is always the current version of the database
        ///   - printTypes: What to output to the console, output using print()
        public init(
            modelName: String,
            bundleIdentifier: String,
            persistentType: PersistentType = .sqlLite,
            persistentOptions: [AnyHashable: Any]? = [NSMigratePersistentStoresAutomaticallyOption: true,
                                                      NSInferMappingModelAutomaticallyOption: true],
            pathDirectory: FileManager.SearchPathDirectory = .documentDirectory,
            modelVersion: Int? = nil,
            printTypes: [PrintType] = []
        ) {
            self.modelName = modelName
            self.fileName = "\(modelName).sqlite"
            self.bundleIdentifier = bundleIdentifier
            self.persistentType = persistentType.value
            self.printTypes = printTypes
            self.pathDirectory = pathDirectory
            self.modelVersion = modelVersion
            self.persistentOptions = persistentOptions ?? [:]
        }

        // MARK: DataBase - API

        /// A string constant (such as NSSQLiteStoreType) that specifies the store type. Default value is 'NSSQLiteStoreType'
        @discardableResult
        public func persistentType(_ persistentType: PersistentType) -> Self {
            self.persistentType = persistentType.value
            return self
        }

        /// The name of the database file that is on the device.
        @discardableResult
        public func fileName(_ fileName: String) -> Self {
            self.fileName = fileName
            return self
        }

        /// What to output to the console, output using print()
        @discardableResult
        public func printTypes(_ printTypes: [PrintType]) -> Self {
            self.printTypes = printTypes
            return self
        }

        /// CoreData coordinator configuration. Default value is [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        @discardableResult
        public func persistentOptions(_ options: [AnyHashable: Any]) -> Self {
            self.persistentOptions = options
            return self
        }

        /// In which directory of the device will the database be located. Default value is FileManager.SearchPathDirectory.cachesDirectory
        @discardableResult
        public func pathDirectory(_ pathDirectory: FileManager.SearchPathDirectory) -> Self {
            self.pathDirectory = pathDirectory
            return self
        }

        /// Version of the model database. 'nil' value is always the current version of the database. Default value is nil (always up-to-date version)
        @discardableResult
        public func modelVersion(_ modelVersion: Int?) -> Self {
            self.modelVersion = modelVersion
            return self
        }
    }
}

// MARK: - Create

extension SafeCoreData.Configuration {
    open class Create {
        public typealias ConcurrencyType = NSManagedObjectContext.ConcurrencyType

        private(set) var concurrency: ConcurrencyType = .async(qos: .userInteractive)

        /// Entity creation. Saves to the database
        /// - Parameter concurrency: How will the operation be performed
        public init(concurrency: ConcurrencyType = .async(qos: .userInteractive)) {
            self.concurrency = concurrency
        }

        // MARK:  Create - API

        /// How will the operation be performed. Default value is '.async'
        @discardableResult
        public func concurrency(_ concurrencyType: ConcurrencyType) -> Self {
            self.concurrency = concurrencyType
            return self
        }

    }
}

// MARK: - Fetch

extension SafeCoreData.Configuration {
    /// Entity  fetch process configuration
    open class Fetch {
        public typealias ConcurrencyType = NSManagedObjectContext.ConcurrencyType

        private(set) var filter: NSPredicate?
        private(set) var sort: [NSSortDescriptor]?
        private(set) var concurrency: ConcurrencyType
        private(set) var fetchBatchSize: Int?
        private(set) var fetchLimit: Int?
        private(set) var fetchOffset: Int = 0
        private(set) var includesSubentities: Bool

        /// Entity  fetch process configuration
        /// - Parameters:
        ///   - filter: The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results
        ///   - sort: Sorting the result.  If the 'nil' value is not sorted
        ///   - concurrency: How will the operation be performed
        ///   - fetchBatchSize: The batch size of the objects specified in the fetch request.
        ///   - fetchLimit: The fetch limit of the fetch request.
        ///   - fetchOffset: The fetch offset of the fetch request. The default value is 0. This setting allows you to specify an offset at which rows will begin being returned. Effectively, the request skips the specified number of matching entries. For example, given a fetch that typically returns a, b, c, d, specifying an offset of 1 will return b, c, d, and an offset of 4 will return an empty array. Offsets are ignored in nested requests such as subqueries. This property can be used to restrict the working set of data. In combination with fetchLimit, you can create a subrange of an arbitrary result set.
        ///   - includesSubentities: A Boolean value that indicates whether the fetch request includes subentities in the results.
        public init(
            filter: NSPredicate? = nil,
            sort: [NSSortDescriptor]? = nil,
            concurrency: ConcurrencyType = .async(qos: .userInteractive),
            fetchBatchSize: Int? = nil,
            fetchLimit: Int? = nil,
            fetchOffset: Int = 0,
            includesSubentities: Bool = true
        ) {
            self.filter = filter
            self.sort = sort
            self.concurrency = concurrency
            self.fetchBatchSize = fetchBatchSize
            self.fetchLimit = fetchLimit
            self.fetchOffset = fetchOffset
            self.includesSubentities = includesSubentities
        }

        // MARK: Fetch - API

        /// The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results. Default value is 'nil'
        @discardableResult
        public func filter(_ filter: NSPredicate) -> Self {
            self.filter = filter
            return self
        }

        /// Sorting the result.  If the 'nil' value is not sorted. Default value is 'nil'
        @discardableResult
        public func sort(_ sort: [NSSortDescriptor]) -> Self {
            self.sort = sort
            return self
        }

        /// How will the operation be performed. Default value is '.async'
        @discardableResult
        public func concurrency(_ concurrencyType: ConcurrencyType) -> Self {
            self.concurrency = concurrencyType
            return self
        }

        /// The batch size of the objects specified in the fetch request.
        @discardableResult
        public func fetchBatchSize(_ fetchBatchSize: Int?) -> Self {
            self.fetchBatchSize = fetchBatchSize
            return self
        }

        /// The fetch limit of the fetch request.
        @discardableResult
        public func fetchLimit(_ fetchLimit: Int?) -> Self {
            self.fetchLimit = fetchLimit
            return self
        }

        /// The fetch offset of the fetch request. The default value is 0. This setting allows you to specify an offset at which rows will begin being returned. Effectively, the request skips the specified number of matching entries. For example, given a fetch that typically returns a, b, c, d, specifying an offset of 1 will return b, c, d, and an offset of 4 will return an empty array. Offsets are ignored in nested requests such as subqueries. This property can be used to restrict the working set of data. In combination with fetchLimit, you can create a subrange of an arbitrary result set.
        @discardableResult
        public func fetchOffset(_ fetchOffset: Int) -> Self {
            self.fetchOffset = fetchOffset
            return self
        }

        /// A Boolean value that indicates whether the fetch request includes subentities in the results.
        @discardableResult
        public func includesSubentities(_ includesSubentities: Bool) -> Self {
            self.includesSubentities = includesSubentities
            return self
        }
    }
}

// MARK: - Remove

extension SafeCoreData.Configuration {
    public typealias ConcurrencyType = NSManagedObjectContext.ConcurrencyType

    /// Entity  remove process configuration
    open class Remove {

        private(set) var filter: NSPredicate?
        private(set) var concurrency: ConcurrencyType = .async(qos: .userInteractive)

        /// Entity  remove process configuration
        /// - Parameters:
        ///   - filter: The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results. Default value is 'nil'
        ///   - concurrency: The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results
        public init(
            filter: NSPredicate? = nil,
            concurrency: ConcurrencyType = .async(qos: .userInteractive)
        ) {
            self.filter = filter
            self.concurrency = concurrency
        }

        // MARK: Remove - API

        /// The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results. Default value is 'nil'
        @discardableResult
        public func filter(_ filter: NSPredicate) -> Self {
            self.filter = filter
            return self
        }

        /// How will the operation be performed. Default value is '.async'
        @discardableResult
        public func concurrency(_ concurrencyType: ConcurrencyType) -> Self {
            self.concurrency = concurrencyType
            return self
        }
    }
}

// MARK: - Helper

extension SafeCoreData.Configuration.DataBase: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(modelName)
        hasher.combine(modelVersion)
        hasher.combine(persistentType)
        hasher.combine(bundleIdentifier)
        hasher.combine(fileName)
        hasher.combine(pathDirectory)

        #if os(macOS)
        if #available(OSX 10.13, *) {
            let data = try? JSONSerialization.data(withJSONObject: persistentOptions, options: .sortedKeys)
            hasher.combine(data)
        } else {
            persistentOptions.sorted(by: { $0.key == $1.key }).forEach {
                let data = try? JSONSerialization.data(withJSONObject: [$0.key: $0.value], options: .fragmentsAllowed)
                hasher.combine(data)
            }
        }
        #else
        if #available(iOS 11.0, *) {
            let data = try? JSONSerialization.data(withJSONObject: persistentOptions, options: .sortedKeys)
            hasher.combine(data)
        } else {
            persistentOptions.sorted(by: { $0.key == $1.key }).forEach {
                let data = try? JSONSerialization.data(withJSONObject: [$0.key: $0.value], options: .fragmentsAllowed)
                hasher.combine(data)
            }
        }
        #endif

    }

    public static func == (lhs: SafeCoreData.Configuration.DataBase, rhs: SafeCoreData.Configuration.DataBase) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
