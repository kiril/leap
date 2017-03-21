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
                               fields: [MutableField<String>("title"),
                                        MutableField<Int>("count")])

    var title: MutableField<String> { return mutable("title") }
    var count: MutableField<Int> { return mutable("count") }

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

    func testInitialization() {
        guard let repr = testRepresentation else {
            fatalError("OMG")
        }
        XCTAssertFalse(repr.isPersistable, "ID required for persistence")
        XCTAssertFalse(repr.isPersisted, "New object can't have been persisted")
        XCTAssertFalse(repr.isDirty, "New object should be clean")
    }
    
    func testPropertyAccess() {
        guard let repr = testRepresentation else {
            fatalError("OMG")
        }
        XCTAssert(repr.title.representation != nil, "Field association")
        XCTAssertEqual(repr.title.value, "A Title", "Field reading")
        XCTAssertEqual(repr.count.value, 0, "Default int value")
    }

    func testPropertyMutation() throws {
        guard let repr = testRepresentation else {
            fatalError("OMG")
        }
        try repr.title.update(to: "Another Title")
        XCTAssertEqual(repr.title.value, "Another Title", "Field mutating")
        XCTAssertTrue(repr.dirtyFields.contains("title"), "Dirty tracking")
        XCTAssertTrue(repr.isDirty, "Dirty state tracking")

        XCTAssertFalse(repr.dirtyFields.contains("count"), "Dirty tracking base")
        try repr.count.update(to: 4)
        XCTAssertEqual(repr.count.value, 4, "Int field mutating")
        XCTAssertTrue(repr.dirtyFields.contains("count"), "Dirty tracking 2")
    }

    func testPropertyTypeChecking() throws {
        guard let repr = testRepresentation else {
            fatalError("OMG")
        }

        XCTAssertThrowsError(try repr.update(field: "title", toValue: 2), "Mutation type checking, wrong value type",
                             {error in XCTAssert({if let se = error as? SchemaError, case SchemaError.invalidValueForField = se { return true } else { return false }}())})
        XCTAssertThrowsError(try repr.update(field: "foob", toValue: 2), "Mutation type checking, invalid key", {error in XCTAssert({if let se = error as? SchemaError, case SchemaError.noSuchField = se { return true } else { return false }}())})
    }
}
