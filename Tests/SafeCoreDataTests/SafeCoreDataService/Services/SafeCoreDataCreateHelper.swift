//
//  SafeCoreDataCreateHelper.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

@testable import SafeCoreData

class SafeCoreDataCreateHelper {

    private let dataStorage: SafeCoreDataService

    init(dataStorage: SafeCoreDataService) {
        self.dataStorage = dataStorage
    }

    func syncCreateObjets(
        count: Int,
        updateProperties: ((Int, UnitTestEntity) -> Void)? = nil,
        success: (() -> Void)? = nil,
        failure: (() -> Void)? = nil) {
            let createStorage = dataStorage.withCreateParameters
            for i in 0 ..< count {
                let result = createStorage
                    .createObjectSync(withType: UnitTestEntity.self, updateProperties: { object in
                        updateProperties?(i,object)
                    })

                switch result.resultType {
                case .success:
                    if i == count - 1 { success?() }

                case .failure:
                    failure?()
                }
            }
        }
}
