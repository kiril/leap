//
//  RepresentationTests.swift
//  Leap
//
//  Created by Kiril Savino on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
@testable import Leap

class TestRepresentation: Representation {
    static var schema = Schema(type: "test",
                               fields: [MutableField<String>("title")])

    var title: MutableField<String> { return mutable("title") }
    init(data: [String:Any]) {
        super.init(schema: TestRepresentation.schema, id: nil, data: data)
    }
}

class RepresentationTests: XCTestCase {
    var testRepresentation: TestRepresentation?

    override func setUp() {
        super.setUp()
        testRepresentation = TestRepresentation(data: ["title": "A Title", "anotherfield": 2])
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testProperties() {
        XCTAssert(testRepresentation!.title.representation != nil, "Title property did in fact get mapped to the current thing")
    }
}
