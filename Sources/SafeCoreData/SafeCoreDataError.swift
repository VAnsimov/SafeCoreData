//
//  SafeCoreDataError.swift
//  SafeCoreData
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
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
