//
//  SafeCoreDataCreateTests.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData
import Combine

class SafeCoreDataCreateTests: XCTestCase {

    private var dataStorage: SafeCoreDataService!
    private var cancellable: Set<AnyCancellable>!

    override func setUpWithError() throws {
        self.dataStorage = SafeCoreDataService(database: .init(modelName: "UnitTestStorage",
                                                               bundleType: .bundle(.module)))
        cancellable = []

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

extension SafeCoreDataCreateTests {

    func testCreateThreadGlobal() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        SafeCoreDataCreate(dataStorage: dataStorage)
            .outputThread(.global)
            .createObject(withType: UnitTestEntity.self, updateProperties: { _ in }, success: { object in
                XCTAssertEqual(Thread.isMainThread, false)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 2)
    }

    func testCreateThreadMain() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        SafeCoreDataCreate(dataStorage: dataStorage)
            .outputThread(.main)
            .createObject(withType: UnitTestEntity.self, updateProperties: { _ in }, success: { object in
                XCTAssertEqual(Thread.isMainThread, true)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 2)
    }

    func testCreateAsync() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        SafeCoreDataCreate(dataStorage: dataStorage)
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            }, success: { object in
                XCTAssertEqual(object.attributeOne, "test")
                XCTAssertEqual(object.attributeTwo, 1234)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 2)
    }

    func testCreateAsyncAwait() async throws {
        let object = try await SafeCoreDataCreate(dataStorage: dataStorage)
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            }).value

        XCTAssertEqual(object.attributeOne, "test")
        XCTAssertEqual(object.attributeTwo, 1234)
    }

    func testCreateCombine() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        let createFuture = SafeCoreDataCreate(dataStorage: dataStorage)
            .createObjectFuture(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            })

        createFuture
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()
                case .finished:
                    break
                }
            }, receiveValue: { result in
                XCTAssertEqual(result.value.attributeOne, "test")
                XCTAssertEqual(result.value.attributeTwo, 1234)
                expectation.fulfill()
            })
            .store(in: &cancellable)

        wait(for: [expectation], timeout: 2)
    }

    func testCreateSync() {
        let result = SafeCoreDataCreate(dataStorage: dataStorage)
            .createObjectSync(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            })

        switch result.resultType {
        case let .success(object):
            XCTAssertNotNil(object.attributeOne)
            XCTAssertNotNil(object.attributeTwo)
            XCTAssertEqual(object.attributeOne, "test")
            XCTAssertEqual(object.attributeTwo, 1234)

        case let .failure(error):
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateChildObjectAsync() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage
        // Create
        SafeCoreDataCreate(dataStorage: dataStorage)
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.child = newObject.createChildObject(updateProperties: { childObject in
                    childObject.attributeOne = "childtest"
                    childObject.attributeTwo = 4321
                    childObject.parrent = newObject
                })

                if newObject.child == nil {
                    XCTFail()
                }
            }, success: { object in
                XCTAssertEqual(object.child?.attributeOne, "childtest")
                XCTAssertEqual(object.child?.attributeTwo, 4321)

                // Fecth
                SafeCoreDataFetch(dataStorage: dataStorage)
                    .fetch(withType: UnitTestEntity.self, success: { fetch in
                        XCTAssertEqual(fetch.count, 1)
                        XCTAssertEqual(fetch[0].child?.attributeOne, "childtest")
                        XCTAssertEqual(fetch[0].child?.attributeTwo, 4321)
                        expectation.fulfill()
                    }, failure: { error in
                        XCTFail(error.localizedDescription)
                        expectation.fulfill()
                    })
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 2)
    }

    func testCreateChildObjectAsyncAwait() async throws {
        let result = try await SafeCoreDataCreate(dataStorage: dataStorage)
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
        let fetchResult = try await SafeCoreDataFetch(dataStorage: dataStorage)
            .fetch(withType: UnitTestEntity.self)

        XCTAssertTrue(fetchResult.value.count == 1)
        XCTAssertEqual(fetchResult.value[0].child?.attributeOne, "childtest")
        XCTAssertEqual(fetchResult.value[0].child?.attributeTwo, 4321)
    }

    func testCreateChildObjectSync() {
        let result = SafeCoreDataCreate(dataStorage: dataStorage)
            .createObjectSync(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.child = newObject.createChildObject(updateProperties: { childObject in
                    childObject.attributeOne = "childtest"
                    childObject.attributeTwo = 4321
                    childObject.parrent = newObject
                })
                if newObject.child == nil {
                    XCTFail()
                }
            })

        switch result.resultType {
        case let .success(object):
            XCTAssertNotNil(object.child?.attributeOne)
            XCTAssertNotNil(object.child?.attributeTwo)
            XCTAssertEqual(object.child?.attributeOne, "childtest")
            XCTAssertEqual(object.child?.attributeTwo, 4321)

        case let .failure(error):
            XCTFail(error.localizedDescription)
        }
    }

    func testStress() {
        func action(totalGroup: DispatchGroup, storage: SafeCoreDataCreate, steps: Int) {
            totalGroup.enter()

            let group = DispatchGroup()

            for _ in 1 ... steps { group.enter() }

            for index in 1 ... steps {
                storage.createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                    newObject.attributeTwo = Int16(index)
                }, success: { object in
                    XCTAssertNotEqual(object.attributeTwo, 0)
                    group.leave()
                }, failure: { error in
                    XCTFail(error.localizedDescription)
                    group.leave()
                })
            }

            _ = group.wait(timeout: .now() + 1)

            group.notify(queue: .main, execute: {
                totalGroup.leave()
            })
        }
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let totalGroup = DispatchGroup()


        let oneCount = 100
        DispatchQueue.global(qos: .userInteractive).async {
            action(totalGroup: totalGroup, storage: SafeCoreDataCreate(dataStorage: self.dataStorage), steps: oneCount)
        }

        let twoCount = 100
        DispatchQueue.global(qos: .userInteractive).async {
            action(totalGroup: totalGroup, storage: SafeCoreDataCreate(dataStorage: self.dataStorage), steps: twoCount)
        }

        let threeCount = 100
        DispatchQueue.global(qos: .userInteractive).async {
            action(totalGroup: totalGroup, storage: SafeCoreDataCreate(dataStorage: self.dataStorage), steps: threeCount)
        }

        let fourCount = 100
        DispatchQueue.global(qos: .userInteractive).async {
            action(totalGroup: totalGroup, storage: SafeCoreDataCreate(dataStorage: self.dataStorage), steps: fourCount)
        }

        _ = totalGroup.wait(timeout: .now() + 2)

        totalGroup.notify(queue: .global(), execute: {
            sleep(3)
            Task {
                let result = try? await SafeCoreDataFetch(dataStorage: self.dataStorage)
                    .fetch(withType: UnitTestEntity.self)

                XCTAssertEqual(result?.value.count ?? 0, oneCount + twoCount + threeCount + fourCount)
                expectation.fulfill()
            }
        })

        wait(for: [expectation], timeout: 20)
    }

    func testCreateObjects() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage
        let count = 30_000

        SafeCoreDataCreate(dataStorage: dataStorage)
            .createListOfObjects(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                }, completion: { result in
                    switch result.resultType {
                    case let .success(objects):
                        XCTAssertEqual(objects.count, count)
                    case let .failure(error):
                        XCTFail(error.localizedDescription)
                    }

                    SafeCoreDataFetch(dataStorage: dataStorage)
                        .sort([.init(key: "attributeTwo", ascending: true)])
                        .fetch(withType: UnitTestEntity.self, completion: { fetchResult in
                            switch fetchResult.resultType {
                            case let .success(objects):
                                XCTAssertEqual(objects.count, count)

                                for index in 0 ..< objects.count {
                                    XCTAssertEqual(objects[index].attributeTwo, Int16(index))
                                }
                            case let .failure(error):
                                XCTFail(error.localizedDescription)
                            }
                            expectation.fulfill()
                        })
                })

        wait(for: [expectation], timeout: 5)
    }

    func testCreateObjectsAsyncAwait() async throws {
        let count = 30_000

        let createResult = try await SafeCoreDataCreate(dataStorage: dataStorage)
            .createListOfObjects(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })

        XCTAssertEqual(createResult.value.count, count)

        let fecthResult = try await SafeCoreDataFetch(dataStorage: dataStorage)
            .sort([.init(key: "attributeTwo", ascending: true)])
            .fetch(withType: UnitTestEntity.self)

        for index in 0 ..< fecthResult.value.count {
            XCTAssertEqual(fecthResult.value[index].attributeTwo, Int16(index))
        }
    }

    func testCreateObjectsCombine() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let count = 30_000

        let createFuture = SafeCoreDataCreate(dataStorage: dataStorage)
            .createListOfObjectsFuture(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })

        let fecthFuture = SafeCoreDataFetch(dataStorage: dataStorage)
            .sort([.init(key: "attributeTwo", ascending: true)])
            .fetchFuture(withType: UnitTestEntity.self)


        createFuture
            .combineLatest(fecthFuture)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()
                case .finished:
                    break
                }
            }, receiveValue: { createResult, fetchResult in
                XCTAssertEqual(createResult.value.count, count)

                for index in 0 ..< fetchResult.value.count {
                    XCTAssertEqual(fetchResult.value[index].attributeTwo, Int16(index))
                }
                expectation.fulfill()
            }).store(in: &cancellable)
        wait(for: [expectation], timeout: 2)

    }

    func testSaveSync() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        // Create
        SafeCoreDataCreate(dataStorage: dataStorage)
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "First recording"
            }, success: { object in
                XCTAssertEqual(object.attributeOne, "First recording")

                object.attributeOne = "update"
                object.saveСhangesSync()

                // Fetch
                SafeCoreDataFetch(dataStorage: self.dataStorage)
                    .fetch(withType: UnitTestEntity.self, success: { objects in
                        XCTAssertEqual(objects.count, 1)
                        XCTAssertEqual(objects[0].attributeOne, "update")
                        expectation.fulfill()
                    }, failure: { error in
                        XCTFail(error.localizedDescription)
                        expectation.fulfill()
                    })
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 2)
    }

    func testSaveAsync() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        // Create
        SafeCoreDataCreate(dataStorage: dataStorage)
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "First recording"
            }, failure: { error in
                XCTFail(error.localizedDescription)
            }, success: { object in
                XCTAssertNotEqual(object.attributeOne,  nil)
                XCTAssertEqual(object.attributeOne, "First recording")

                object.attributeOne = "update"

                // Save
                object.saveСhangesAsync(sucsess: {

                    // Fetch
                    SafeCoreDataFetch(dataStorage: dataStorage)
                        .fetch(withType: UnitTestEntity.self, success: { fetch in
                            XCTAssertEqual(fetch.count, 1)
                            XCTAssertEqual(fetch[0].attributeOne!, "update")
                            expectation.fulfill()

                        }, failure: { error in
                            XCTFail(error.localizedDescription)
                        })
                }, failure: { error in
                    XCTFail(error.localizedDescription)
                })
            })

        wait(for: [expectation], timeout: 2)
    }
}
