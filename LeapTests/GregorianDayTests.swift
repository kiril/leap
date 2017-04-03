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
    
    func testInitFunctionsEquivilant() {
        let inputDay = 2
        let inputMonth = 2
        let inputYear = 2016

        let day = GregorianDay(day: inputDay, month: inputMonth, year: inputYear)!

        XCTAssertEqual(inputDay, day.day)
        XCTAssertEqual(inputMonth, day.month)
        XCTAssertEqual(inputYear, day.year)

        let id = day.id
        let idInitDay = GregorianDay(id: id)

        XCTAssertEqual(inputDay, idInitDay.day)
        XCTAssertEqual(inputMonth, idInitDay.month)
        XCTAssertEqual(inputYear, idInitDay.year)
    }

    func testEpochIsDayOne() {
        let epochById = GregorianDay(id: 1)
        XCTAssertEqual(1, epochById.day)
        XCTAssertEqual(1, epochById.month)
        XCTAssertEqual(1970, epochById.year)

        let epochByComponents = GregorianDay(day: 1, month: 1, year: 1970)!
        XCTAssertEqual(1, epochByComponents.id)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
