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
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
