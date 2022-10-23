//
//  SafeCoreData+ResultData.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import CoreData

extension SafeCoreData {
    public struct ResultData<T> {

        // MARK: Public

        public let resultType: Result<T, SafeCoreDataError>

        public var value: T? {
            switch resultType {
            case let .success(data):
                return data

            case .failure:
                return nil
            }
        }

        public var error: SafeCoreDataError? {
            switch resultType {
            case .success:
                return nil

            case let .failure(error):
                return error
            }
        }

        // MARK: Private

        // Needed so that NSManagedObject is not deleted
        let context: NSManagedObjectContext

        // MARK: Life cycle

        init(result: Result<T, SafeCoreDataError>, context: NSManagedObjectContext) {
            self.resultType = result
            self.context = context
        }
    }
}
