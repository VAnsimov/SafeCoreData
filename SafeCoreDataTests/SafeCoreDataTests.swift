//
//  SafeCoreDataTests.swift
//  SafeCoreDataTests
//
//  Created by Vyacheslav Ansimov on 13.10.2019.
//  Copyright © 2019 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData

class SafeCoreDataTests: XCTestCase {

    var dataStorage: SafeCoreData!


    // MARK: Live cycle SafeCoreDataTests

    override func setUp() {

        let bundleIdentifier = Bundle(for: type(of: self)).bundleIdentifier!
        self.dataStorage = SafeCoreData(database: .init(modelName: "UnitTestStorage",
                                                         bundleIdentifier: bundleIdentifier))

        // Clears the database
        let removecConfig = SafeConfiguration.Remove().concurrency(.sync)
        self.dataStorage.remove(type: UnitTestEntity.self, configure: removecConfig)
    }

    override func tearDown() {
        // Clears the database
        let removecConfig = SafeConfiguration.Remove().concurrency(.sync)
        self.dataStorage.remove(type: UnitTestEntity.self, configure: removecConfig)
    }

    // MARK: Create and Update

    func testCreateAsync() {
        let createAsyncExpectation = XCTestExpectation(description: "createAsyncExpectation callback should be called")

        // Create
        dataStorage.create(type: UnitTestEntity.self, updateProperties: { newObject in
            newObject.attributeOne = "test"
            newObject.attributeTwo = 1234
        }, success: { object in
            XCTAssertNotNil(object.attributeOne)
            XCTAssertEqual(object.attributeOne!, "test")
            XCTAssertEqual(object.attributeTwo, 1234)
            createAsyncExpectation.fulfill()

        }, fail: { _ in XCTAssert(false); createAsyncExpectation.fulfill() })

        wait(for: [createAsyncExpectation], timeout: 2)
    }

    func testCreateSync() {
        let config = SafeConfiguration.Create().concurrency(.sync)
        var isSuccess = false

        dataStorage.create(type: UnitTestEntity.self, configure: config, updateProperties: { newObject in
            newObject.attributeOne = "test"
            newObject.attributeTwo = 1234
            isSuccess = true
        }, success: { object in
            XCTAssertNotNil(object.attributeOne)
            XCTAssertEqual(object.attributeOne!, "test")
            XCTAssertEqual(object.attributeTwo, 1234)
        }, fail: { _ in  XCTAssert(false) })

        XCTAssertTrue(isSuccess)
    }

    func testUpdateSync() {
        let updateSyncExpectation = XCTestExpectation(description: "updateSyncExpectation callback should be called")

        dataStorage.create(type: UnitTestEntity.self, updateProperties: { newObject in
            newObject.attributeOne = "First recording"
        }, success: { object in
            XCTAssertTrue(object.attributeOne != nil)
            XCTAssertTrue(object.attributeOne! == "First recording")

            object.attributeOne = "update"

            object.saveСhangesSync()

            self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)
                XCTAssertEqual(fetch[0].attributeOne!, "update")
                updateSyncExpectation.fulfill()

            }, fail: { _ in XCTAssert(false); updateSyncExpectation.fulfill() })
        }, fail: { _ in XCTAssert(false); updateSyncExpectation.fulfill() })

        wait(for: [updateSyncExpectation], timeout: 2)
    }

    func testUpdateAsync() {
        let updateSyncExpectation = XCTestExpectation(description: "updateSyncExpectation callback should be called")

        dataStorage.create(type: UnitTestEntity.self, updateProperties: { newObject in
            newObject.attributeOne = "First recording"
        }, success: { object in
            XCTAssertTrue(object.attributeOne != nil)
            XCTAssertTrue(object.attributeOne! == "First recording")

            object.attributeOne = "update"

            object.saveСhangesAsync(sucsess: {
                self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                    XCTAssertEqual(fetch.count, 1)
                    XCTAssertEqual(fetch[0].attributeOne!, "update")
                    updateSyncExpectation.fulfill()

                }, fail: { _ in XCTAssert(false); updateSyncExpectation.fulfill() })
            }, fail: { _ in XCTAssert(false); updateSyncExpectation.fulfill() })
        }, fail: { _ in XCTAssert(false); updateSyncExpectation.fulfill() })

        wait(for: [updateSyncExpectation], timeout: 2)
    }

    // MARK: Fetch

    func testFetchSync() {
        let createConfig = SafeConfiguration.Create().concurrency(.sync)
        var isSuccess = false

        dataStorage.create(type: UnitTestEntity.self, configure: createConfig, updateProperties: { newObject in
            newObject.attributeOne = "test"
            newObject.attributeTwo = 1234
        }, fail: { _ in  XCTAssert(false) })

        let fetchConfig = SafeConfiguration.Fetch().concurrency(.sync)
        self.dataStorage.fetch(withType: UnitTestEntity.self, configure: fetchConfig, success: { fetch in
            XCTAssertEqual(fetch.count, 1)
            isSuccess = true
        }, fail: { _ in XCTAssert(false) })

        XCTAssertTrue(isSuccess)
    }

    func testFetchPredicate() {
        let fetchPredicateExpectation = XCTestExpectation(description:
            "fetchPredicateExpectation callback should be called"
        )

        create(count: 100, updateProperties: { (index, newObject) in
            newObject.attributeTwo = Int16(index)
        }, success: {
            let searchIndex = Int16(3)
            let config = SafeConfiguration.Fetch().filter(NSPredicate(format: "attributeTwo == \(searchIndex)"))

            self.dataStorage.fetch(withType: UnitTestEntity.self, configure: config, success: { fetch in
                XCTAssertEqual(fetch.count, 1)
                XCTAssertEqual(fetch[0].attributeTwo, searchIndex)
                fetchPredicateExpectation.fulfill()

            }, fail: { _ in XCTAssert(false); fetchPredicateExpectation.fulfill() })
        }, fail: { XCTAssert(false); fetchPredicateExpectation.fulfill() })

        wait(for: [fetchPredicateExpectation], timeout: 10)
    }

    func testFetchSort() {
        let fetchSortExpectation = XCTestExpectation(description: "fetchSortExpectation callback should be called")

        create(count: 100, updateProperties: { (_, newObject) in
            newObject.attributeTwo = Int16.random(in: 0 ..< 1000)
        }, success: {

            let config = SafeConfiguration.Fetch().sort([NSSortDescriptor(key: "attributeTwo", ascending: false)])

            self.dataStorage.fetch(withType: UnitTestEntity.self, configure: config, success: { fetch in
                var previousValue: Int16 = fetch[0].attributeTwo
                for item in fetch {
                    guard item.attributeTwo <= previousValue else {
                        XCTAssert(false)
                        fetchSortExpectation.fulfill()
                        return
                    }
                    previousValue = item.attributeTwo
                }
                XCTAssert(true)
                fetchSortExpectation.fulfill()

            }, fail: { _ in XCTAssert(false); fetchSortExpectation.fulfill() })
        }, fail: { XCTAssert(false); fetchSortExpectation.fulfill() })

        wait(for: [fetchSortExpectation], timeout: 10)
    }

    // MARK: Remove

    func testRemoveSync() {
        let count = 100
        var isSuccess = false

        let createConfig = SafeConfiguration.Create().concurrency(.sync)
        for i in 0 ..< count {
            dataStorage.create(type: UnitTestEntity.self, configure: createConfig, updateProperties: { newObject in
                newObject.attributeTwo = Int16(i)
            }, fail: { _ in  XCTAssert(false) })
        }

        let removeConfig = SafeConfiguration.Remove().concurrency(.sync)
        self.dataStorage.remove(type: UnitTestEntity.self, configure: removeConfig, success: { ids in
            XCTAssertEqual(ids.count, count)
            isSuccess = true
        }, fail: { _ in XCTAssert(false)})

        XCTAssertTrue(isSuccess)
    }

    func testRemove() {
        let removeExpectation = XCTestExpectation(description: "removeExpectation callback should be called")
        let count = 100

        // Create
        create(count: count, updateProperties: nil, success: {

            // Remove
            self.dataStorage.remove(type: UnitTestEntity.self, success: { ids in
                XCTAssertEqual(ids.count, count)
                removeExpectation.fulfill()

            }, fail: { _ in XCTAssert(false); removeExpectation.fulfill() })
        }, fail: { XCTAssert(false); removeExpectation.fulfill() })

        wait(for: [removeExpectation], timeout: 10)
    }

    func testRemovePredicate() {
        let removePredicateExpectation = XCTestExpectation(description:
            "removePredicateExpectation callback should be called"
        )

        // Create
        let count = 100
        create(count: count, updateProperties: { (index, newObject) in
            newObject.attributeTwo = Int16(index)
        }, success: {

            // Remove
            let searchIndex = Int16(3)
            let config = SafeConfiguration.Remove().filter(NSPredicate(format: "attributeTwo != \(searchIndex)"))

            self.dataStorage.remove(type: UnitTestEntity.self, configure: config, success: { ids in
                XCTAssertTrue(ids.count == count - 1)

                self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                    XCTAssertEqual(fetch.count, 1)
                    XCTAssertEqual(fetch[0].attributeTwo, searchIndex)
                    removePredicateExpectation.fulfill()

                }, fail: { _ in XCTAssert(false); removePredicateExpectation.fulfill() })
            },fail: { _ in XCTAssert(false); removePredicateExpectation.fulfill() })
        }, fail: { XCTAssert(false); removePredicateExpectation.fulfill() })

        wait(for: [removePredicateExpectation], timeout: 10)
    }

    func testDeleteAsync() {
        let deleteAsyncExpectation = XCTestExpectation(description: "deleteAsyncExpectation callback should be called")

        create(updateProperties: nil, success: {
            self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)

                fetch[0].deleteAsync(sucsess: {

                    self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                        XCTAssertEqual(fetch.count, 0)
                        deleteAsyncExpectation.fulfill()

                    }, fail: { _ in XCTAssert(false); deleteAsyncExpectation.fulfill() })
                }, fail: { _ in XCTAssert(false); deleteAsyncExpectation.fulfill() })
            }, fail: { _ in XCTAssert(false); deleteAsyncExpectation.fulfill() })
        }, fail: { XCTAssert(false); deleteAsyncExpectation.fulfill() })

        wait(for: [deleteAsyncExpectation], timeout: 2)
    }

    func testDeleteSync() {
        let deleteSyncExpectation = XCTestExpectation(description: "deleteSyncExpectation callback should be called")

        create(updateProperties: nil, success: {
            self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)

                fetch[0].deleteSync()

                self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                    XCTAssertEqual(fetch.count, 0)
                    deleteSyncExpectation.fulfill()

                }, fail: { _ in XCTAssert(false); deleteSyncExpectation.fulfill() })
            }, fail: { _ in XCTAssert(false); deleteSyncExpectation.fulfill() })
        }, fail: { XCTAssert(false); deleteSyncExpectation.fulfill() })

        wait(for: [deleteSyncExpectation], timeout: 2)
    }

}

// MARK: - Helper functions
extension SafeCoreDataTests {

    func create(count: Int = 1,
                updateProperties: ((Int, UnitTestEntity) -> Void)?,
                success: @escaping () -> Void,
                fail: @escaping () -> Void) {
        let config = SafeConfiguration.Create()

        for i in 0 ..< count {
            dataStorage.create(type: UnitTestEntity.self,
                               configure: config.concurrency(.sync),
                               updateProperties: { object in
                updateProperties?(i,object)
            }, success: { object in
                if i == count - 1 { success() }
            }, fail: { error in
                fail()
            })
        }
    }

}

