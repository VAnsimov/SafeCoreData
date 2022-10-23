//
//  SafeCoreDataFetchTests.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData
import Combine

// MARK: - Fetch

class SafeCoreDataFetchTests: XCTestCase {

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

extension SafeCoreDataFetchTests {

    func testFetchThreadGlobal() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        SafeCoreDataFetch(dataStorage: dataStorage)
            .outputThread(.global)
            .fetch(withType: UnitTestEntity.self, success: { object in
                XCTAssertEqual(Thread.isMainThread, false)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 2)
    }

    func testFetchThreadMain() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        SafeCoreDataFetch(dataStorage: dataStorage)
            .outputThread(.main)
            .fetch(withType: UnitTestEntity.self, success: { object in
                XCTAssertEqual(Thread.isMainThread, true)
                expectation.fulfill()
            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 2)
    }

    func testFetchSync() {
        // Create synn
        let createResult = SafeCoreDataCreate(dataStorage: dataStorage)
            .createObjectSync(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            })

        switch createResult.resultType {
        case let .success(object):
            XCTAssertNotNil(object.attributeOne)
            XCTAssertNotNil(object.attributeTwo)
            XCTAssertEqual(object.attributeOne, "test")
            XCTAssertEqual(object.attributeTwo, 1234)

        case let .failure(error):
            XCTFail(error.localizedDescription)
        }

        // Fetch sync
        let fecthResult = SafeCoreDataFetch(dataStorage: dataStorage)
            .fetchSync(withType: UnitTestEntity.self)

        switch fecthResult.resultType {
        case let .success(data):
            XCTAssertEqual(data.count, 1)
            XCTAssertNotNil(data[0].attributeOne)
            XCTAssertNotNil(data[0].attributeTwo)
            XCTAssertEqual(data[0].attributeOne, "test")
            XCTAssertEqual(data[0].attributeTwo, 1234)

        case let .failure(error):
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchCombine() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        // Create
        let createObjectFuture = SafeCoreDataCreate(dataStorage: dataStorage)
            .createObjectFuture(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            })

        // Fetch
        let fetchFuture = SafeCoreDataFetch(dataStorage: dataStorage)
            .fetchFuture(withType: UnitTestEntity.self).eraseToAnyPublisher()

        createObjectFuture
            .flatMap { _ in fetchFuture }
            .sink { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()

                case .finished:
                    break
                }
            } receiveValue: { fetchResult in
                XCTAssertEqual(fetchResult.value.count, 1)
                XCTAssertEqual(fetchResult.value[0].attributeOne, "test")
                XCTAssertEqual(fetchResult.value[0].attributeTwo, 1234)
                expectation.fulfill()
            }.store(in: &cancellable)

        wait(for: [expectation], timeout: 20)
    }

    func testFetchPredicate() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")

        // Create
        createHelper.syncCreateObjets(count: 100, updateProperties: { (index, newObject) in
            newObject.attributeTwo = Int16(index)
        }, failure: {
            XCTFail()
        })

        let searchIndex = Int16(3)

        SafeCoreDataFetch(dataStorage: self.dataStorage)
            .filter(NSPredicate(format: "attributeTwo == \(searchIndex)"))
            .fetch(withType: UnitTestEntity.self, completion: { result in
                switch result.resultType {
                case let .success(objects):
                    XCTAssertEqual(objects.count, 1)
                    XCTAssertEqual(objects[0].attributeTwo, searchIndex)

                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 10)
    }

    func testFetchSort() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        // Create
        createHelper.syncCreateObjets(count: 100, updateProperties: { (_, newObject) in
            newObject.attributeTwo = Int16.random(in: 0 ..< 1000)
        }, failure: {
            XCTFail()
        })

        // Fetch
        SafeCoreDataFetch(dataStorage: dataStorage)
            .sort([NSSortDescriptor(key: "attributeTwo", ascending: false)])
            .fetch(withType: UnitTestEntity.self, success: { objects in
                var previousValue: Int16 = objects[0].attributeTwo

                for item in objects {
                    guard previousValue >= item.attributeTwo else {
                        XCTFail()
                        expectation.fulfill()
                        return
                    }
                    previousValue = item.attributeTwo
                }
                XCTAssert(true)
                expectation.fulfill()

            }, failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 10)
    }
}
