//
//  SafeCoreData+DataBase.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import CoreData

extension SafeCoreData.DataBase {

    ///  Database settings
    open class Configuration {

        public enum PrintType {
            case pathCoreData(prefix: String? = nil, postfix: String? = nil)
        }

        public enum BundleDataType {
            case identifier(String), bundle(Bundle)
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
        let bundleType: BundleDataType
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
            bundleType: BundleDataType,
            persistentType: PersistentType = .sqlLite,
            persistentOptions: [AnyHashable: Any]? = [NSMigratePersistentStoresAutomaticallyOption: true,
                                                            NSInferMappingModelAutomaticallyOption: true],
            pathDirectory: FileManager.SearchPathDirectory = .documentDirectory,
            modelVersion: Int? = nil,
            printTypes: [PrintType] = []
        ) {
            self.modelName = modelName
            self.fileName = "\(modelName).sqlite"
            self.bundleType = bundleType
            self.persistentType = persistentType.value
            self.printTypes = printTypes
            self.pathDirectory = pathDirectory
            self.modelVersion = modelVersion
            self.persistentOptions = persistentOptions ?? [:]
        }

        // MARK: API

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
// MARK: - Hashable

extension SafeCoreData.DataBase.Configuration: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(modelName)
        hasher.combine(modelVersion)
        hasher.combine(persistentType)
        hasher.combine(fileName)
        hasher.combine(pathDirectory)

        switch bundleType {
        case let .bundle(data):
            hasher.combine(data)

        case let .identifier(data):
            hasher.combine(data)
        }

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

    public static func == (lhs: SafeCoreData.DataBase.Configuration,
                           rhs: SafeCoreData.DataBase.Configuration) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
