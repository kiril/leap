//
//  BridgeTest.swift
//  Leap
//
//  Created by Kiril Savino on 3/31/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
import RealmSwift

@testable import Leap



class BridgeTest: XCTestCase {

    let testId: String = "testmodel"
    var testSurface: TestSurface?
    
    override func setUp() {
        super.setUp()
        let model = TestModel(value: ["id": testId, "title": "Just a Test", "count": 8])
        let realm = Realm.user()
        try! realm.write {
            realm.add(model, update: true)
        }
        testSurface = TestSurface.load(byId: "testmodel")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPopulation() {
        guard let model = TestModel.by(id: testId), let surface = testSurface else {
            fatalError("yikes")
        }
        XCTAssertEqual(surface.count.value, model.count)
        XCTAssertEqual(surface.title.value, model.title)
    }

    func testPersistence() {
        guard let model = TestModel.by(id: testId), let surface = testSurface else {
            fatalError("yikes")
        }
        surface.title.update(to: "New Title")
        XCTAssertNotEqual(surface.title.value, model.title)
        try! surface.flush()
        XCTAssertEqual(surface.title.value, model.title)

        let reFetched = TestModel.by(id: model.id)
        XCTAssertNotNil(reFetched)
        XCTAssertEqual(reFetched!.title, surface.title.value)
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
