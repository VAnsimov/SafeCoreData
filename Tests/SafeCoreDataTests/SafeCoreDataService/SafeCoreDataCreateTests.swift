//
//  SafeCoreDataCreateTests.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData

class SafeCoreDataCreateTests: XCTestCase {

    private var dataStorage: SafeCoreDataService!

    override func setUpWithError() throws {
        self.dataStorage = try? SafeCoreDataService(database: .init(
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

extension SafeCoreDataCreateTests {

    func testCreateThreadGlobal() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        dataStorage
            .withCreateParameters
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

        dataStorage
            .withCreateParameters
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

        dataStorage
            .withCreateParameters
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

    func testCreateSync() {
        let result = dataStorage
            .withCreateParameters
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
        dataStorage
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
            }, success: { object in
                XCTAssertEqual(object.child?.attributeOne, "childtest")
                XCTAssertEqual(object.child?.attributeTwo, 4321)

                // Fecth
                dataStorage
                    .withFetchParameters
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

    func testCreateChildObjectSync() {
        let result = dataStorage
            .withCreateParameters
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
        func action(totalGroup: DispatchGroup, storage: SafeCoreData.Service.Create, steps: Int) {
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
            action(totalGroup: totalGroup, storage: self.dataStorage.withCreateParameters, steps: oneCount)
        }

        let twoCount = 100
        DispatchQueue.global(qos: .userInteractive).async {
            action(totalGroup: totalGroup, storage: self.dataStorage.withCreateParameters, steps: twoCount)
        }

        let threeCount = 100
        DispatchQueue.global(qos: .userInteractive).async {
            action(totalGroup: totalGroup, storage: self.dataStorage.withCreateParameters, steps: threeCount)
        }

        let fourCount = 100
        DispatchQueue.global(qos: .userInteractive).async {
            action(totalGroup: totalGroup, storage: self.dataStorage.withCreateParameters, steps: fourCount)
        }

        _ = totalGroup.wait(timeout: .now() + 2)

        totalGroup.notify(queue: .global(), execute: {
            sleep(3)
            Task {
                let result = try? await self.dataStorage
                    .withFetchParameters
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

        dataStorage
            .withCreateParameters
            .createListOfObjects(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                }, completion: { [weak self] result in
                    switch result.resultType {
                    case let .success(objects):
                        XCTAssertEqual(objects.count, count)
                    case let .failure(error):
                        XCTFail(error.localizedDescription)
                    }

                    self?.dataStorage
                        .withFetchParameters
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

    func testSaveSync() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        // Create
        dataStorage
            .withCreateParameters
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "First recording"
            }, success: { [weak self] object in
                XCTAssertEqual(object.attributeOne, "First recording")

                object.attributeOne = "update"
                object.saveСhangesSync()

                // Fetch
                self?.dataStorage
                    .withFetchParameters
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
        dataStorage
            .withCreateParameters
            .createObject(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "First recording"
            }, failure: { error in
                XCTFail(error.localizedDescription)
            }, success: { [weak self] object in
                XCTAssertNotEqual(object.attributeOne,  nil)
                XCTAssertEqual(object.attributeOne, "First recording")

                object.attributeOne = "update"

                // Save
                object.saveСhangesAsync(sucsess: {

                    // Fetch
                    self?.dataStorage
                        .withFetchParameters
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
