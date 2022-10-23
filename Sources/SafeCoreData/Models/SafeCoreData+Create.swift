//
//  SafeCoreData+Create.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation

extension SafeCoreData.Create {
    open class ConfigurationSync {
        public init() {}
    }

    open class Configuration: ConfigurationSync {
        private(set) var outputThread: SafeCoreData.ContextOutputThread

        /// Entity creation. Saves to the database
        /// - Parameters:
        ///   - outputThread: In which queue the result will be returned. By default the .main
        public init(outputThread: SafeCoreData.ContextOutputThread = .main) {
            self.outputThread = outputThread

            super.init()
        }

        // MARK:  Create - API

        /// In which queue the result will be returned. By default the .main
        @discardableResult
        public func outputThread(_ outputThread: SafeCoreData.ContextOutputThread) -> Self {
            self.outputThread = outputThread
            return self
        }
    }
}
