//
//  SafeCoreDataAwaitRemoveTests.swift
//
//  Created by Vyacheslav Ansimov on 03.11.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData

class SafeCoreDataAwaitRemoveTests: XCTestCase {

    private var dataStorage: SafeCoreDataService!
    private var createHelper: SafeCoreDataCreateHelper!

    override func setUp() {
        dataStorage = try? SafeCoreDataService(database: .init(
            modelName: "UnitTestStorage",
            bundleType: .bundle(.module)))

        createHelper = SafeCoreDataCreateHelper(dataStorage: dataStorage)

        // Clears the database
        _ = self.dataStorage.removeSync(withType: UnitTestEntity.self)
    }

    override func tearDown() {
        // Clears the database
        _ = self.dataStorage.removeSync(withType: UnitTestEntity.self)
    }
}

extension SafeCoreDataAwaitRemoveTests {

    func testAllRemove() async throws {
        let count = 3_000

        // Create
        try await dataStorage
            .withCreateParameters
            .createListOfObjects(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })

        let fetchResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)
        XCTAssertEqual(fetchResult.value.count, count)

        // Remove
        let removeResult = try await dataStorage
            .withRemoveParameters
            .remove(withType: UnitTestEntity.self)
        let ids = removeResult.value
        XCTAssertEqual(ids.count, count)

        let fetchEmptyResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)
        XCTAssertEqual(fetchEmptyResult.value.count, 0)
    }

    func testFilterRemove() async throws {
        let count = 3_000

        // Create
        try await dataStorage
            .withCreateParameters
            .createListOfObjects(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })

        // Remove
        let removeResult = try await dataStorage
            .withRemoveParameters
            .filter(NSPredicate(format: "attributeTwo > 2000"))
            .remove(withType: UnitTestEntity.self)

        let ids = removeResult.value

        XCTAssertEqual(ids.count, 999)

        let fetchResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)

        for object in fetchResult.value {
            XCTAssertTrue(object.attributeTwo <= 2000)
        }
    }

    func testDelete() async throws {
        try await dataStorage
            .withCreateParameters
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "delete"
            })

        let fetchResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)
        XCTAssertEqual(fetchResult.value.count, 1)

        let deleteResult = await fetchResult.value.first?.delete()

        switch deleteResult {
        case .success:
            break

        case let .failure(error):
            XCTFail(error.localizedDescription)

        case .none:
            XCTFail()
        }

        let fetchEmptyResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)

        XCTAssertEqual(fetchEmptyResult.value.count, 0)
    }
}

