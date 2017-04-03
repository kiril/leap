//
//  BridgeTest.swift
//  Leap
//
//  Created by Kiril Savino on 3/31/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest

@testable import Leap



class BridgeTest: XCTestCase {

    var model: TestModel?
    var surface: TestSurface?
    
    override func setUp() {
        super.setUp()
        model = TestModel(value: ["id": "testmodel", "title": "Just a Test", "count": 8])
        model!.register()
        surface = TestSurface.load(byId: "testmodel")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPopulation() {
        XCTAssertEqual(surface!.count.value, model!.count)
        XCTAssertEqual(surface!.title.value, model!.title)
    }

    func testPersistence() {
        try! surface!.title.update(to: "New Title")
        XCTAssertNotEqual(surface!.title.value, model!.title)
        try! surface!.flush()
        XCTAssertEqual(surface!.title.value, model!.title)
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
