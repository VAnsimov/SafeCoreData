//
//  SafeCoreData.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import CoreData

public typealias SafeCoreDataFetch = SafeCoreData.Service.Fetch
public typealias SafeCoreDataCreate = SafeCoreData.Service.Create
public typealias SafeCoreDataRemove = SafeCoreData.Service.Remove

public enum SafeCoreData {
    public enum DataBase {}
    public enum Create {}
    public enum Fetch {}
    public enum Remove {}
    public enum Service {}
}
