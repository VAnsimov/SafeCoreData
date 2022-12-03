//
//  SafeCoreDataCombineCreateTests.swift
//
//  Created by Vyacheslav Ansimov on 03.12.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData
import Combine

class SafeCoreDataCombineCreateTests: XCTestCase {

    private var dataStorage: SafeCoreDataService!
    private var cancellable: Set<AnyCancellable>!

    override func setUpWithError() throws {
        self.dataStorage = try? SafeCoreDataService(database: .init(
            modelName: "UnitTestStorage",
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

extension SafeCoreDataCombineCreateTests {

    func testCreateObject() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage
        
        dataStorage
            .withCreateParameters
            .createObjectFuture(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            })
            .flatMap { createResult in
                XCTAssertEqual(createResult.value.attributeOne, "test")
                XCTAssertEqual(createResult.value.attributeTwo, 1234)

                return dataStorage
                    .withFetchParameters
                    .fetchFuture(withType: UnitTestEntity.self)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()

                case .finished:
                    break
                }
            }, receiveValue: { fetchResult in
                XCTAssertEqual(fetchResult.value.count, 1)
                XCTAssertEqual(fetchResult.value.first?.attributeOne, "test")
                XCTAssertEqual(fetchResult.value.first?.attributeTwo, 1234)

                expectation.fulfill()
            }).store(in: &cancellable)
        wait(for: [expectation], timeout: 2)
    }

    func testCreateChildObject() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        // Create
        let createFuture = dataStorage
            .withCreateParameters
            .createObjectFuture(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "parrent"
                newObject.attributeTwo = 2

                newObject.child = newObject.createChildObject(updateProperties: { childObject in
                    childObject.attributeOne = "childtest"
                    childObject.attributeTwo = 4321
                    childObject.parrent = newObject
                })
            })

        let fecthFuture = dataStorage
            .withFetchParameters
            .fetchFuture(withType: UnitTestEntity.self)

        createFuture
            .flatMap { createResult in
                XCTAssertEqual(createResult.value.attributeOne, "parrent")
                XCTAssertEqual(createResult.value.attributeTwo, 2)
                XCTAssertEqual(createResult.value.child?.attributeOne, "childtest")
                XCTAssertEqual(createResult.value.child?.attributeTwo, 4321)
                return fecthFuture
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()

                case .finished:
                    break
                }
            }, receiveValue: { fetchResult in
                XCTAssertEqual(fetchResult.value.count, 1)
                XCTAssertEqual(fetchResult.value.first?.attributeOne, "parrent")
                XCTAssertEqual(fetchResult.value.first?.attributeTwo, 2)
                XCTAssertEqual(fetchResult.value.first?.child?.attributeOne, "childtest")
                XCTAssertEqual(fetchResult.value.first?.child?.attributeTwo, 4321)

                expectation.fulfill()
            }).store(in: &cancellable)

        wait(for: [expectation], timeout: 2)
    }

    func testCreateObjects() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let count = 30_000
        let dataStorage: SafeCoreDataService = dataStorage

        dataStorage
            .withCreateParameters
            .createListOfObjectsFuture(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })
            .flatMap { createResult in
                XCTAssertEqual(createResult.value.count, count)
                for index in 0 ..< createResult.value.count {
                    XCTAssertEqual(createResult.value[index].attributeTwo, Int16(index))
                }

                return dataStorage
                    .withFetchParameters
                    .sort([.init(key: "attributeTwo", ascending: true)])
                    .fetchFuture(withType: UnitTestEntity.self)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()
                case .finished:
                    break
                }
            }, receiveValue: { fetchResult in
                XCTAssertEqual(fetchResult.value.count, count)

                for index in 0 ..< fetchResult.value.count {
                    XCTAssertEqual(fetchResult.value[index].attributeTwo, Int16(index))
                }
                expectation.fulfill()
            }).store(in: &cancellable)

        wait(for: [expectation], timeout: 2)

    }

    func testSave() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        dataStorage
            .withCreateParameters
            .createObjectFuture(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "First recording"
                newObject.attributeTwo = 42
            })
            .flatMap { createResult in
                XCTAssertEqual(createResult.value.attributeOne, "First recording")
                XCTAssertEqual(createResult.value.attributeTwo, 42)

                createResult.value.attributeOne = "new text"
                return createResult.value.saveСhangesFeature()
            }
            .flatMap { _ in
                dataStorage
                    .withFetchParameters
                    .fetchFuture(withType: UnitTestEntity.self)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()

                case .finished:
                    break
                }
            }, receiveValue: { fetchResult in
                XCTAssertEqual(fetchResult.value.count, 1)
                XCTAssertEqual(fetchResult.value.first?.attributeOne, "new text")
                XCTAssertEqual(fetchResult.value.first?.attributeTwo, 42)

                expectation.fulfill()
            }).store(in: &cancellable)

        wait(for: [expectation], timeout: 2)
    }
}
