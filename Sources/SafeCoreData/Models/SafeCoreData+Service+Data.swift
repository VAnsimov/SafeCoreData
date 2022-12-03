//
//  SafeCoreData+Service.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import CoreData

extension SafeCoreData.Service {
    public struct Data<T> {

        // MARK: Public

        public var value: T

        // MARK: Private

        // Needed so that NSManagedObject is not deleted
        private let context: NSManagedObjectContext

        // MARK: Life cycle

        init(value: T, context: NSManagedObjectContext) {
            self.value = value
            self.context = context
        }
    }
}
