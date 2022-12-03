//
//  SafeCoreDataCombineFetchTests.swift
//
//  Created by Vyacheslav Ansimov on 03.12.2022.
//  Copyright © 2022 Vyacheslav Ansimov. All rights reserved.
//

import XCTest
@testable import SafeCoreData
import Combine

// MARK: - Fetch

class SafeCoreDataCombineFetchTests: XCTestCase {

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

extension SafeCoreDataCombineFetchTests {

    func testFetchCombine() {
        let expectation = XCTestExpectation(description: "failure: expectation - \(#function)")
        let dataStorage: SafeCoreDataService = dataStorage

        dataStorage
            .withCreateParameters
            .createObjectFuture(withType: UnitTestEntity.self, updateProperties: { newObject in
                newObject.attributeOne = "test"
                newObject.attributeTwo = 1234
            })
            .flatMap { _ in
                dataStorage
                    .withFetchParameters
                    .fetchFuture(withType: UnitTestEntity.self)
                    .eraseToAnyPublisher()
            }
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

}
