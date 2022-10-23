//
//  SafeCoreData+Fetch.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation

// MARK: - Configuration

extension SafeCoreData.Fetch {
    /// Entity  fetch process configuration
    open class ConfigurationSync {
        private(set) var filter: NSPredicate?
        private(set) var sort: [NSSortDescriptor]?
        private(set) var fetchBatchSize: Int?
        private(set) var fetchLimit: Int?
        private(set) var fetchOffset: Int
        private(set) var includesSubentities: Bool

        /// Entity  fetch process configuration
        /// - Parameters:
        ///   - filter: The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results
        ///   - sort: Sorting the result.  If the 'nil' value is not sorted
        ///   - fetchBatchSize: The batch size of the objects specified in the fetch request.
        ///   - fetchLimit: The fetch limit of the fetch request.
        ///   - fetchOffset: The fetch offset of the fetch request. The default value is 0. This setting allows you to specify an offset at which rows will begin being returned. Effectively, the request skips the specified number of matching entries. For example, given a fetch that typically returns a, b, c, d, specifying an offset of 1 will return b, c, d, and an offset of 4 will return an empty array. Offsets are ignored in nested requests such as subqueries. This property can be used to restrict the working set of data. In combination with fetchLimit, you can create a subrange of an arbitrary result set.
        ///   - includesSubentities: A Boolean value that indicates whether the fetch request includes subentities in the results.
        public init(
            filter: NSPredicate? = nil,
            sort: [NSSortDescriptor]? = nil,
            fetchBatchSize: Int? = nil,
            fetchLimit: Int? = nil,
            fetchOffset: Int = 0,
            includesSubentities: Bool = true
        ) {
            self.filter = filter
            self.sort = sort
            self.fetchBatchSize = fetchBatchSize
            self.fetchLimit = fetchLimit
            self.fetchOffset = fetchOffset
            self.includesSubentities = includesSubentities
        }

        // MARK: API

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

    /// Entity  fetch process configuration
    open class Configuration: ConfigurationSync {

        private(set) var outputThread: SafeCoreData.ContextOutputThread

        /// Entity  fetch process configuration
        /// - Parameters:
        ///   - filter: The principle of searching for entities in the database. When 'nil' the filter will not be applied, it will give all the results
        ///   - sort: Sorting the result.  If the 'nil' value is not sorted
        ///   - outputThread: In which queue the result will be returned. By default the .main
        ///   - fetchBatchSize: The batch size of the objects specified in the fetch request.
        ///   - fetchLimit: The fetch limit of the fetch request.
        ///   - fetchOffset: The fetch offset of the fetch request. The default value is 0. This setting allows you to specify an offset at which rows will begin being returned. Effectively, the request skips the specified number of matching entries. For example, given a fetch that typically returns a, b, c, d, specifying an offset of 1 will return b, c, d, and an offset of 4 will return an empty array. Offsets are ignored in nested requests such as subqueries. This property can be used to restrict the working set of data. In combination with fetchLimit, you can create a subrange of an arbitrary result set.
        ///   - includesSubentities: A Boolean value that indicates whether the fetch request includes subentities in the results.
        public init(
            filter: NSPredicate? = nil,
            sort: [NSSortDescriptor]? = nil,
            outputThread: SafeCoreData.ContextOutputThread = .main,
            fetchBatchSize: Int? = nil,
            fetchLimit: Int? = nil,
            fetchOffset: Int = 0,
            includesSubentities: Bool = true
        ) {
            self.outputThread = outputThread

            super.init(
                filter: filter,
                sort: sort,
                fetchBatchSize: fetchBatchSize,
                fetchLimit: fetchLimit,
                fetchOffset: fetchOffset,
                includesSubentities: includesSubentities)
        }

        // MARK: Fetch - API

        /// In which queue the result will be returned. By default the .main
        @discardableResult
        public func outputThread(_ outputThread: SafeCoreData.ContextOutputThread) -> Self {
            self.outputThread = outputThread
            return self
        }
    }
}
