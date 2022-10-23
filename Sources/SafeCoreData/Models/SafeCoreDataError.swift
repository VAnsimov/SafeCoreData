//
//  SafeCoreDataError.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import Foundation

public enum SafeCoreDataError: Error {
    case noDataBaseModel
    case failGetContext
    case failFetchComponent(message: String)
    case noProperty(propertyName: String)
    case failSave
    case objectInDatabaseIs
    case failCreate
    case failRemove
    case save(error: Error)
}
