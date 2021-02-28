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
}

// MARK: - Create and Save

extension SafeCoreDataTests {
    func testCreateAsync() {
        let expectation = XCTestExpectation(description: "fail: expectation - testCreateAsync()")

        dataStorage.create(type: UnitTestEntity.self, updateProperties: { newObject in
            newObject.attributeOne = "test"
            newObject.attributeTwo = 1234
        }, success: { object in
            XCTAssertNotNil(object.attributeOne)
            XCTAssertNotNil(object.attributeTwo)
            XCTAssertEqual(object.attributeOne!, "test")
            XCTAssertEqual(object.attributeTwo, 1234)
            expectation.fulfill()

        }, fail: { _ in XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 2)
    }

    func testCreateSync() {
        let config = SafeConfiguration.Create().concurrency(.sync)
        var isSuccess = false

        dataStorage.create(type: UnitTestEntity.self, configure: config, updateProperties: { newObject in
            newObject.attributeOne = "test"
            newObject.attributeTwo = 1234
        }, success: { object in
            XCTAssertNotNil(object.attributeOne)
            XCTAssertNotNil(object.attributeTwo)
            XCTAssertEqual(object.attributeOne!, "test")
            XCTAssertEqual(object.attributeTwo, 1234)
            isSuccess = true
        }, fail: { _ in  XCTAssert(false) })

        XCTAssertTrue(isSuccess)
    }

    func testCreateChildObjectAsync() {
        let expectation = XCTestExpectation(description: "fail: expectation - testCreateChildObjectAsync()")

        // Create
        dataStorage.create(type: UnitTestEntity.self, updateProperties: { newObject in
            if let child: UnitTestChildEntity = newObject.createChildObject(updateProperties: { childObject in
                childObject.attributeOne = "childtest"
                childObject.attributeTwo = 4321
                childObject.parrent = newObject
            }) {
                newObject.child = child
            } else {
                XCTAssert(false)
                expectation.fulfill()
            }
        }, success: { object in
            XCTAssertNotNil(object.child?.attributeOne)
            XCTAssertNotNil(object.child?.attributeTwo)
            XCTAssertEqual(object.child!.attributeOne!, "childtest")
            XCTAssertEqual(object.child!.attributeTwo, 4321)

            // Fecth
            self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertTrue(fetch.count == 1)
                XCTAssertNotNil(fetch[0].child?.attributeOne)
                XCTAssertNotNil(fetch[0].child?.attributeTwo)
                XCTAssertEqual(fetch[0].child!.attributeOne!, "childtest")
                XCTAssertEqual(fetch[0].child!.attributeTwo, 4321)
                expectation.fulfill()
            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { _ in  XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 2)
    }

    func testCreateChildObjectSync() {
        let config = SafeConfiguration.Create().concurrency(.sync)
        var isSuccess = false

        dataStorage.create(type: UnitTestEntity.self, configure: config, updateProperties: { newObject in
            if let child: UnitTestChildEntity = newObject.createChildObject(updateProperties: { childObject in
                childObject.attributeOne = "childtest"
                childObject.attributeTwo = 4321
                childObject.parrent = newObject
            }) {
                newObject.child = child
            } else {
                XCTAssert(false)
            }
        }, success: { object in
            XCTAssertNotNil(object.child?.attributeOne)
            XCTAssertNotNil(object.child?.attributeTwo)
            XCTAssertEqual(object.child!.attributeOne!, "childtest")
            XCTAssertEqual(object.child!.attributeTwo, 4321)
            isSuccess = true
        }, fail: { _ in  XCTAssert(false) })

        XCTAssertTrue(isSuccess)
    }

    func testSaveSync() {
        let expectation = XCTestExpectation(description: "fail: expectation - testSaveSync()")

        // Create
        dataStorage.create(type: UnitTestEntity.self, updateProperties: { newObject in
            newObject.attributeOne = "First recording"
        }, success: { object in
            XCTAssertTrue(object.attributeOne != nil)
            XCTAssertTrue(object.attributeOne! == "First recording")

            object.attributeOne = "update"

            object.saveСhangesSync()

            // Fecth
            self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)
                XCTAssertEqual(fetch[0].attributeOne!, "update")
                expectation.fulfill()

            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { _ in XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 2)
    }

    func testSaveAsync() {
        let expectation = XCTestExpectation(description: "fail: expectation - testSaveAsync()")

        // Create
        dataStorage.create(type: UnitTestEntity.self, updateProperties: { newObject in
            newObject.attributeOne = "First recording"
        }, success: { object in
            XCTAssertTrue(object.attributeOne != nil)
            XCTAssertTrue(object.attributeOne! == "First recording")

            object.attributeOne = "update"

            // Save
            object.saveСhangesAsync(sucsess: {

                // Fetch
                self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                    XCTAssertEqual(fetch.count, 1)
                    XCTAssertEqual(fetch[0].attributeOne!, "update")
                    expectation.fulfill()

                }, fail: { _ in XCTAssert(false); expectation.fulfill() })
            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { _ in XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 2)
    }
}

// MARK: - Fetch

extension SafeCoreDataTests {
    func testFetchSync() {
        let createConfig = SafeConfiguration.Create().concurrency(.sync)
        var isSuccess = false

        // Create synn
        dataStorage.create(type: UnitTestEntity.self, configure: createConfig, updateProperties: { newObject in
            newObject.attributeOne = "test"
            newObject.attributeTwo = 1234
        }, fail: { _ in  XCTAssert(false) })

        // Fetch sync
        let fetchConfig = SafeConfiguration.Fetch().concurrency(.sync)
        self.dataStorage.fetch(withType: UnitTestEntity.self, configure: fetchConfig, success: { fetch in
            XCTAssertEqual(fetch.count, 1)
            isSuccess = true
        }, fail: { _ in XCTAssert(false) })

        XCTAssertTrue(isSuccess)
    }

    func testFetchPredicate() {
        let expectation = XCTestExpectation(description: "fail: expectation - testFetchPredicate()")

        // Create
        create(count: 100, updateProperties: { (index, newObject) in
            newObject.attributeTwo = Int16(index)
        }, success: {
            let searchIndex = Int16(3)
            let config = SafeConfiguration.Fetch().filter(NSPredicate(format: "attributeTwo == \(searchIndex)"))

            // Fetch
            self.dataStorage.fetch(withType: UnitTestEntity.self, configure: config, success: { fetch in
                XCTAssertEqual(fetch.count, 1)
                XCTAssertEqual(fetch[0].attributeTwo, searchIndex)
                expectation.fulfill()

            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 10)
    }

    func testFetchSort() {
        let expectation = XCTestExpectation(description: "fail: expectation - testFetchSort()")

        // Create
        create(count: 100, updateProperties: { (_, newObject) in
            newObject.attributeTwo = Int16.random(in: 0 ..< 1000)
        }, success: {

            let config = SafeConfiguration.Fetch().sort([NSSortDescriptor(key: "attributeTwo", ascending: false)])

            // Fetch
            self.dataStorage.fetch(withType: UnitTestEntity.self, configure: config, success: { fetch in
                var previousValue: Int16 = fetch[0].attributeTwo
                for item in fetch {
                    guard item.attributeTwo <= previousValue else {
                        XCTAssert(false)
                        expectation.fulfill()
                        return
                    }
                    previousValue = item.attributeTwo
                }
                XCTAssert(true)
                expectation.fulfill()

            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 10)
    }
}

// MARK: - Remove

extension SafeCoreDataTests {
    func testRemoveSync() {
        let count = 100
        var isSuccess = false

        // Create sync
        let createConfig = SafeConfiguration.Create().concurrency(.sync)
        for i in 0 ..< count {
            dataStorage.create(type: UnitTestEntity.self, configure: createConfig, updateProperties: { newObject in
                newObject.attributeTwo = Int16(i)
            }, fail: { _ in  XCTAssert(false) })
        }

        // Create remove
        let removeConfig = SafeConfiguration.Remove().concurrency(.sync)
        self.dataStorage.remove(type: UnitTestEntity.self, configure: removeConfig, success: { ids in
            XCTAssertEqual(ids.count, count)
            isSuccess = true
        }, fail: { _ in XCTAssert(false)})

        XCTAssertTrue(isSuccess)
    }

    func testRemove() {
        let expectation = XCTestExpectation(description: "fail: expectation - testRemove()")
        let count = 100

        // Create
        create(count: count, updateProperties: nil, success: {

            // Remove
            self.dataStorage.remove(type: UnitTestEntity.self, success: { ids in
                XCTAssertEqual(ids.count, count)
                expectation.fulfill()

            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 10)
    }

    func testRemovePredicate() {
        let expectation = XCTestExpectation(description: "fail: expectation - testRemovePredicate()")

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
                    expectation.fulfill()

                }, fail: { _ in XCTAssert(false); expectation.fulfill() })
            },fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 10)
    }

    func testDeleteAsync() {
        let expectation = XCTestExpectation(description: "fail: expectation - testDeleteAsync()")

        // Create
        create(updateProperties: nil, success: {

            // Fetch
            self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)

                // Remove
                fetch[0].deleteAsync(sucsess: {

                    // Fetch
                    self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                        XCTAssertEqual(fetch.count, 0)
                        expectation.fulfill()

                    }, fail: { _ in XCTAssert(false); expectation.fulfill() })
                }, fail: { _ in XCTAssert(false); expectation.fulfill() })
            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 2)
    }

    func testDeleteSync() {
        let expectation = XCTestExpectation(description: "fail: expectation - testDeleteSync()")

        // Create
        create(updateProperties: nil, success: {

            // Fetch
            self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)

                // Remove
                fetch[0].deleteSync()

                // Fetch
                self.dataStorage.fetch(withType: UnitTestEntity.self, success: { fetch in
                    XCTAssertEqual(fetch.count, 0)
                    expectation.fulfill()

                }, fail: { _ in XCTAssert(false); expectation.fulfill() })
            }, fail: { _ in XCTAssert(false); expectation.fulfill() })
        }, fail: { XCTAssert(false); expectation.fulfill() })

        wait(for: [expectation], timeout: 2)
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

