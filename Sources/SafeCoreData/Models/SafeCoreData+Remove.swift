//
//  SafeCoreData+Remove.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation

extension SafeCoreData.Remove {
    /// Entity  remove process configuration
    open class ConfigurationSync {

        private(set) var filter: NSPredicate?

        /// Entity  remove process configuration
        /// - Parameters:
        ///   - filter: The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results. Default value is 'nil'
        public init(filter: NSPredicate? = nil) {
            self.filter = filter
        }

        // MARK: Remove - API

        /// The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results. Default value is 'nil'
        @discardableResult
        public func filter(_ filter: NSPredicate) -> Self {
            self.filter = filter
            return self
        }
    }

    /// Entity  remove process configuration
    open class Configuration: ConfigurationSync {

        private(set) var outputThread: SafeCoreData.ContextOutputThread

        /// Entity  remove process configuration
        /// - Parameters:
        ///   - filter: The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results. Default value is 'nil'
        ///   - outputThread: In which queue the result will be returned. By default the .main
        public init(
            filter: NSPredicate? = nil,
            outputThread: SafeCoreData.ContextOutputThread = .main
        ) {
            self.outputThread = outputThread

            super.init(filter: filter)
        }

        // MARK: Remove - API

        /// In which queue the result will be returned. By default the .main
        @discardableResult
        public func outputThread(_ outputThread: SafeCoreData.ContextOutputThread) -> Self {
            self.outputThread = outputThread
            return self
        }
    }
}
