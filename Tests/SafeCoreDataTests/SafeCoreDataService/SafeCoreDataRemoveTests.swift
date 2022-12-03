//
//  SafeCoreDataRemoveTests.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData

class SafeCoreDataRemoveTests: XCTestCase {

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

extension SafeCoreDataRemoveTests {

    func testRemoveThreadGlobal() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        dataStorage
            .withRemoveParameters
            .outputThread(.global)
            .remove(withType: UnitTestEntity.self, success: { object in
                XCTAssertEqual(Thread.isMainThread, false)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 2)
    }

    func testRemoveThreadMain() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        dataStorage
            .withRemoveParameters
            .outputThread(.main)
            .remove(withType: UnitTestEntity.self, success: { object in
                XCTAssertEqual(Thread.isMainThread, true)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 2)
    }

    func testRemoveSync() {
        let count = 100

        // Create sync
        createHelper.syncCreateObjets(count: count, updateProperties: { (index, newObject) in
            newObject.attributeTwo = Int16(index)
        }, failure: {
            XCTFail()
        })

        // Create remove
        let result = dataStorage
            .withRemoveParameters
            .removeSync(withType: UnitTestEntity.self)

        switch result.resultType {
        case let .success(ids):
            XCTAssertEqual(ids.count, count)

        case let .failure(error):
            XCTFail(error.localizedDescription)
        }
    }

    func testRemove() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let count = 100

        // Create
        createHelper.syncCreateObjets(count: count, updateProperties: nil, success: nil, failure: {
            XCTFail()
        })

        // Remove
        dataStorage
            .withRemoveParameters
            .remove(withType: UnitTestEntity.self, success: { ids in
                XCTAssertEqual(ids.count, count)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 10)
    }

    func testRemovePredicate() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let count = 100
        let dataStorage: SafeCoreDataService = dataStorage

        // Create
        createHelper.syncCreateObjets(count: count, updateProperties: { (index, newObject) in
            newObject.attributeTwo = Int16(index)
        }, failure: {
            XCTFail()
        })

        let searchIndex = Int16(3)

        // Remove
        dataStorage
            .withRemoveParameters
            .filter(NSPredicate(format: "attributeTwo != \(searchIndex)"))
            .remove(withType: UnitTestEntity.self, success: { [weak self] ids in
                XCTAssertEqual(ids.count, count - 1)

                // Fetch
                self?.dataStorage
                    .withFetchParameters
                    .fetch(withType: UnitTestEntity.self, success: { objects in
                        XCTAssertEqual(objects.count, 1)
                        XCTAssertEqual(objects[0].attributeTwo, searchIndex)
                        expectation.fulfill()

                    }, failure: { error in
                        XCTFail(error.localizedDescription)
                        expectation.fulfill()
                    })
            },failure: { error in
                XCTFail(error.localizedDescription);
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 10)
    }

    func testDeleteAsync() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        // Create
        createHelper.syncCreateObjets(count: 1, failure: {
            XCTFail()
        })

        // Fetch
        dataStorage
            .withFetchParameters
            .fetch(withType: UnitTestEntity.self, success: { [weak self] fetch in
                XCTAssertEqual(fetch.count, 1)

                // Remove
                fetch[0].deleteAsync(sucsess: {

                    // Fetch
                    self?.dataStorage
                        .withFetchParameters
                        .fetch(withType: UnitTestEntity.self, success: { fetch in
                            XCTAssertEqual(fetch.count, 0)
                            expectation.fulfill()

                        }, failure: { error in
                            XCTFail(error.localizedDescription);
                            expectation.fulfill()
                        })
                }, failure: { error in
                    XCTFail(error.localizedDescription);
                    expectation.fulfill()
                })
            }, failure: { error in
                XCTFail(error.localizedDescription);
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 2)
    }

    func testDeleteSync() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        // Create
        createHelper.syncCreateObjets(count: 1, failure: {
            XCTFail()
        })

        let fetchService = dataStorage
            .withFetchParameters

        // Fetch
        fetchService
            .fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)

                // Remove
                fetch[0].deleteSync()

                // Fetch
                fetchService
                    .fetch(withType: UnitTestEntity.self, success: { fetch in
                        XCTAssertEqual(fetch.count, 0)
                        expectation.fulfill()

                    }, failure: {  error in
                        XCTFail(error.localizedDescription);
                        expectation.fulfill()
                    })
            }, failure: {  error in
                XCTFail(error.localizedDescription);
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 2)
    }
}

