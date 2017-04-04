//
//  CalendarTests.swift
//  Leap
//
//  Created by Kiril Savino on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
import Foundation

@testable import Leap

class CalendarTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFormatDisplayTimeAM() {
        let calendar = Calendar.current
        let components = DateComponents(calendar: calendar, hour: 9, minute: 5)
        let date = calendar.date(from: components)!
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: false), "9:05")
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: true), "9:05am")
    }

    func testFormatDisplayTimePM() {
        let calendar = Calendar.current
        let components = DateComponents(calendar: calendar, hour: 21, minute: 5)
        let date = calendar.date(from: components)!
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: false), "9:05")
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: true), "9:05pm")
    }

    func testConvenientComparison() {
        let a = Calendar.current.todayAt(hour: 9, minute: 0)
        let b = Calendar.current.todayAt(hour: 10, minute: 0)
        XCTAssertTrue(Calendar.current.isDate(a, before: b))
        XCTAssertTrue(Calendar.current.isDate(b, after: a))


        let c = Calendar.current.todayAt(hour: 9, minute: 0)
        let d = Calendar.current.todayAt(hour: 9, minute: 0)
        XCTAssertFalse(Calendar.current.isDate(c, before: d))
        XCTAssertFalse(Calendar.current.isDate(c, after: d))


        let e = Calendar.current.todayAt(hour: 9, minute: 0)
        let f = Calendar.current.todayAt(hour: 9, minute: 1)
        XCTAssertTrue(Calendar.current.isDate(e, before: f))
        XCTAssertTrue(Calendar.current.isDate(f, after: e))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
