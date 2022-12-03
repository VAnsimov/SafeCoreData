//
//  SafeCoreDataAwaitCreateTests.swift
//
//  Created by Vyacheslav Ansimov on 03.12.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData

class SafeCoreDataAwaitCreateTests: XCTestCase {

    private var dataStorage: SafeCoreDataService!

    override func setUpWithError() throws {
        self.dataStorage = try?  SafeCoreDataService(database: .init(
            modelName: "UnitTestStorage",
            bundleType: .bundle(.module)))

        // Clears the database
        let result = self.dataStorage.removeSync(withType: UnitTestEntity.self)
        if let error = result.error {
            throw error
        }
    }

    override func tearDownWithError() throws {
        // Clears the database
        _ = self.dataStorage.removeSync(withType: UnitTestEntity.self)

        let result = self.dataStorage.removeSync(withType: UnitTestEntity.self)
        if let error = result.error {
            throw error
        }
    }
}

extension SafeCoreDataAwaitCreateTests {

    func testCreate() async throws {
        let result = try await dataStorage
            .withCreateParameters
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            })
        let object = result.value
        XCTAssertEqual(object.attributeOne, "test")
        XCTAssertEqual(object.attributeTwo, 1234)
    }

    func testCreateObject() async throws {
        let result = try await dataStorage
            .withCreateParameters
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "Two"
                newObject.attributeTwo = 2
            })

        XCTAssertEqual(result.value.attributeOne, "Two")
        XCTAssertEqual(result.value.attributeTwo, 2)

        // Fecth
        let fetchResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)

        XCTAssertTrue(fetchResult.value.count == 1)
        XCTAssertEqual(fetchResult.value[0].attributeOne, "Two")
        XCTAssertEqual(fetchResult.value[0].attributeTwo, 2)
    }

    func testCreateChildObject() async throws {
        let result = try await dataStorage
            .withCreateParameters
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.child = newObject.createChildObject(updateProperties: { childObject in
                    childObject.attributeOne = "childtest"
                    childObject.attributeTwo = 4321
                    childObject.parrent = newObject
                })

                if newObject.child == nil {
                    XCTFail()
                }
            })

        XCTAssertEqual(result.value.child?.attributeOne!, "childtest")
        XCTAssertEqual(result.value.child?.attributeTwo, 4321)

        // Fecth
        let fetchResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)

        XCTAssertTrue(fetchResult.value.count == 1)
        XCTAssertEqual(fetchResult.value[0].child?.attributeOne, "childtest")
        XCTAssertEqual(fetchResult.value[0].child?.attributeTwo, 4321)
    }

    func testCreateObjects() async throws {
        let count = 30_000

        let createResult = try await dataStorage
            .withCreateParameters
            .createListOfObjects(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })

        XCTAssertEqual(createResult.value.count, count)

        let fecthResult = try await dataStorage
            .withFetchParameters
            .sort([.init(key: "attributeTwo", ascending: true)])
            .fetch(withType: UnitTestEntity.self)

        for index in 0 ..< fecthResult.value.count {
            XCTAssertEqual(fecthResult.value[index].attributeTwo, Int16(index))
        }
    }

    func testSave() async throws {
        // Create
        let result = try await dataStorage
            .withCreateParameters
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "First recording"
            })

        let object = result.value
        XCTAssertNotEqual(object.attributeTwo, nil)
        XCTAssertEqual(object.attributeOne, "First recording")


        object.attributeOne = "update"

        // Save
        let saveSatus = await object.saveСhanges()

        switch saveSatus {
        case .success:
            break

        case let .failure(error):
            XCTFail(error.localizedDescription)
        }

        // Fecth
        let fetchResult = try await dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self)

        let fetchObjects = fetchResult.value
        XCTAssertEqual(fetchObjects.count, 1)
        XCTAssertEqual(fetchObjects[0].attributeOne, "update")
    }
}
