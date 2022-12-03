//
//  SafeCoreDataCombineRemoveTests.swift
//
//  Created by Vyacheslav Ansimov on 23.10.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData
import Combine
import CoreData

class SafeCoreDataCombineRemoveTests: XCTestCase {

    private var dataStorage: SafeCoreDataService!
    private var createHelper: SafeCoreDataCreateHelper!
    private var cancellable: Set<AnyCancellable>!

    override func setUp() {
        dataStorage = try? SafeCoreDataService(database: .init(
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

extension SafeCoreDataCombineRemoveTests {

    func testAllRemove() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage
        let count = 100

        dataStorage
            .withCreateParameters
            .createListOfObjectsFuture(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })
            .flatMap { createResult -> AnyPublisher<SafeCoreData.Service.Data<[UnitTestEntity]>, SafeCoreDataError> in
                XCTAssertEqual(createResult.value.count, count)

                // Fetch
                return dataStorage
                    .withFetchParameters
                    .fetchFuture(withType: UnitTestEntity.self)
            }
            .flatMap { fetchResult -> AnyPublisher<SafeCoreData.Service.Data<[NSManagedObjectID]>, SafeCoreDataError> in
                XCTAssertEqual(fetchResult.value.count, count)

                // Remove
                return dataStorage
                    .withRemoveParameters
                    .removeFuture(withType: UnitTestEntity.self)
            }
            .flatMap { removeResult -> AnyPublisher<SafeCoreData.Service.Data<[UnitTestEntity]>, SafeCoreDataError> in
                XCTAssertEqual(removeResult.value.count, count)

                // Fetch
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
                XCTAssertEqual(fetchResult.value.count, 0)
                expectation.fulfill()
            })
            .store(in: &cancellable)

        wait(for: [expectation], timeout: 2)
    }

    func testRemovePredicate() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage
        let count = 100
        let searchIndex = Int16(3)

        dataStorage
            .withCreateParameters
            .createListOfObjectsFuture(
                withType: UnitTestEntity.self,
                list: Array(0 ..< count),
                updateProperties: { item, newObject in
                    newObject.attributeTwo = Int16(item)
                })
            .flatMap { createResult -> AnyPublisher<SafeCoreData.Service.Data<[UnitTestEntity]>, SafeCoreDataError> in
                XCTAssertEqual(createResult.value.count, count)

                // Fetch
                return dataStorage
                    .withFetchParameters
                    .fetchFuture(withType: UnitTestEntity.self)
            }
            .flatMap { fetchResult -> AnyPublisher<SafeCoreData.Service.Data<[NSManagedObjectID]>, SafeCoreDataError> in
                XCTAssertEqual(fetchResult.value.count, count)

                // Remove
                return dataStorage
                    .withRemoveParameters
                    .filter(NSPredicate(format: "attributeTwo != \(searchIndex)"))
                    .removeFuture(withType: UnitTestEntity.self)
            }
            .flatMap { removeResult -> AnyPublisher<SafeCoreData.Service.Data<[UnitTestEntity]>, SafeCoreDataError> in
                XCTAssertEqual(removeResult.value.count, count - 1)

                // Fetch
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
                XCTAssertEqual(fetchResult.value.first?.attributeTwo, searchIndex)
                expectation.fulfill()
            })
            .store(in: &cancellable)

        wait(for: [expectation], timeout: 10)
    }

    func testDelete() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        dataStorage
            .withCreateParameters
            .createObjectFuture(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeTwo = 56
            })
            .flatMap { createResult -> AnyPublisher<SafeCoreData.Service.Data<[UnitTestEntity]>, SafeCoreDataError> in
                XCTAssertEqual(createResult.value.attributeTwo, 56)

                // Fetch
                return dataStorage
                    .withFetchParameters
                    .fetchFuture(withType: UnitTestEntity.self)
            }
            .flatMap { fetchResult -> AnyPublisher<Void, SafeCoreDataError> in
                XCTAssertEqual(fetchResult.value.count, 1)
                XCTAssertEqual(fetchResult.value.first?.attributeTwo, 56)

                // Remove
                return fetchResult.value.first?.deleteFeature() ?? Empty().eraseToAnyPublisher()
            }
            .flatMap { _ -> AnyPublisher<SafeCoreData.Service.Data<[UnitTestEntity]>, SafeCoreDataError> in
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
                XCTAssertEqual(fetchResult.value.count, 0)
                expectation.fulfill()
            })
            .store(in: &cancellable)

        wait(for: [expectation], timeout: 2)
    }
}

