//
//  SafeCoreDataRemoveTests.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData
import Combine

class SafeCoreDataRemoveTests: XCTestCase {

    private var dataStorage: SafeCoreDataService!
    private var createHelper: SafeCoreDataCreateHelper!
    private var cancellable: Set<AnyCancellable>!

    override func setUp() {
        dataStorage = SafeCoreDataService(database: .init(
            modelName: "UnitTestStorage",
            bundleType: .bundle(.module)))

        createHelper = SafeCoreDataCreateHelper(dataStorage: dataStorage)
        cancellable = []

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

        SafeCoreDataRemove(dataStorage: dataStorage)
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

        SafeCoreDataRemove(dataStorage: dataStorage)
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
        let result = SafeCoreDataRemove(dataStorage: dataStorage)
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
        SafeCoreDataRemove(dataStorage: dataStorage)
            .remove(withType: UnitTestEntity.self, success: { ids in
                XCTAssertEqual(ids.count, count)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 10)
    }

    func testRemoveCombine() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let count = 100

        // Create
        createHelper.syncCreateObjets(count: count, updateProperties: nil, success: nil, failure: {
            XCTFail()
        })

        // Remove
        let removeFuture = SafeCoreDataRemove(dataStorage: dataStorage)
            .removeFuture(withType: UnitTestEntity.self)

        // Fetch
        let fetchFuture = SafeCoreDataFetch(dataStorage: dataStorage)
            .fetchFuture(withType: UnitTestEntity.self)

        removeFuture
            .combineLatest(fetchFuture)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()

                case .finished:
                    break
                }
            }, receiveValue: { removeResult, fetchResult in
                XCTAssertEqual(removeResult.value.count, count)
                XCTAssertEqual(fetchResult.value.count, 0)
                expectation.fulfill()
            })
            .store(in: &cancellable)

        wait(for: [expectation], timeout: 2)
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
        SafeCoreDataRemove(dataStorage: dataStorage)
            .filter(NSPredicate(format: "attributeTwo != \(searchIndex)"))
            .remove(withType: UnitTestEntity.self, success: { ids in
                XCTAssertEqual(ids.count, count - 1)

                // Fetch
                SafeCoreDataFetch(dataStorage: dataStorage)
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
        SafeCoreDataFetch(dataStorage: dataStorage)
            .fetch(withType: UnitTestEntity.self, success: { fetch in
                XCTAssertEqual(fetch.count, 1)

                // Remove
                fetch[0].deleteAsync(sucsess: {

                    // Fetch
                    SafeCoreDataFetch(dataStorage: dataStorage)
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

        let fetchService = SafeCoreDataFetch(dataStorage: dataStorage)

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

