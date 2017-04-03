//
//  GregorianDayTests.swift
//  Leap
//
//  Created by Chris Ricca on 4/2/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
@testable import Leap

class GregorianDayTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitFunctions() {
        let inputDay = 2
        let inputMonth = 2
        let inputYear = 2016

        let day = GregorianDay(day: inputDay, month: inputMonth, year: inputYear)!

        XCTAssertEqual(inputDay, day.day)
        XCTAssertEqual(inputMonth, day.month)
        XCTAssertEqual(inputYear, day.year)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
