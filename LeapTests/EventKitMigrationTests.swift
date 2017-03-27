//
//  EventKitMigrationTests.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
import RealmSwift
import EventKit
@testable import Leap

class EventKitMigrationTests: XCTestCase {
    var realm: Realm?
    
    override func setUp() {
        super.setUp()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "EventKitMigrationTest"))
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRecurrence() {
        let ek1 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.daily,
                                 interval: 1, end: EKRecurrenceEnd(occurrenceCount: 2))
        let r1: Recurrence = ek1.asRecurrence()
        XCTAssertEqual(r1.count, 2)
        XCTAssertEqual(r1.interval, 1)
        XCTAssertEqual(r1.frequency, Frequency.daily)
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
