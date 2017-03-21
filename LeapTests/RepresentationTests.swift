//
//  RepresentationTests.swift
//  Leap
//
//  Created by Kiril Savino on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
import Darwin
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

    func testPropertyRemoval() throws {
        guard let repr = testRepresentation else {
            fatalError("OMG")
        }

        XCTAssertEqual(repr.title.value, "A Title", "Sane starting point")
        try repr.title.clear()
        XCTAssertEqual(repr.title.value, "", "Title is cleared")
        XCTAssertEqual(repr.title.rawValue, nil, "Title is cleared")
    }

    func testObservation() throws {
        class DumbObserver: RepresentationObserver {
            var sourceId: String
            var observedChange: Bool = false

            init() {
                self.sourceId = "DumbObserver-\(arc4random_uniform(100000))"
            }

            func representationDidChange(_ representation: Representation) {
                observedChange = true
            }

            func reset() {
                observedChange = false
            }
        }

        guard let repr = testRepresentation else {
            fatalError("OMG")
        }

        let dumb1 = DumbObserver()

        repr.register(observer: dumb1)
        try repr.title.update(to: "Well, New Titles Abound")
        XCTAssertTrue(dumb1.observedChange, "Observer was notified")

        dumb1.reset()
        XCTAssertFalse(dumb1.observedChange, "Reset")
        try repr.title.update(to: "New Title 2", silently: true)
        XCTAssertFalse(dumb1.observedChange, "Silent didn't notify observer")

        let dumb2 = DumbObserver()

        XCTAssertFalse(dumb2.observedChange, "Just Checking")

        repr.register(observer: dumb2)
        try repr.title.update(to: "OMG A Title")
        XCTAssertTrue(dumb1.observedChange, "Still goes to original")
        XCTAssertTrue(dumb2.observedChange, "And goes to the new one")

        dumb1.reset()
        dumb2.reset()
        try repr.title.update(to: "The Best Title Ever", silently: true)
        XCTAssertFalse(dumb1.observedChange, "Silent")
        XCTAssertFalse(dumb2.observedChange, "Silent")

        try repr.title.update(to: "A Real Title", via: dumb1)
        XCTAssertFalse(dumb1.observedChange, "No looping please")
        XCTAssertTrue(dumb2.observedChange, "But other observers get the change")
    }
}
