//
//  EventSurfaceTests.swift
//  Leap
//
//  Created by Kiril Savino on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest

@testable import Leap

class EventSurfaceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTimeRangeCrossingNoon() {
        let start = Calendar.current.todayAt(hour: 9, minute: 30)
        let end = Calendar.current.todayAt(hour: 13, minute: 0)
        let surface = EventSurface(mockData: ["startTime": start, "endTime": end])
        XCTAssertEqual(surface.timeString.value, "9:30am - 1pm")
    }

    func testTimeRangeToNoon() {
        let start = Calendar.current.todayAt(hour: 9, minute: 30)
        let end = Calendar.current.todayAt(hour: 12, minute: 0)
        let surface = EventSurface(mockData: ["startTime": start, "endTime": end])
        XCTAssertEqual(surface.timeString.value, "9:30am - 12pm")
    }

    func testTimeRangeMorning() {
        let start = Calendar.current.todayAt(hour: 9, minute: 30)
        let end = Calendar.current.todayAt(hour: 10, minute: 0)
        let surface = EventSurface(mockData: ["startTime": start, "endTime": end])
        XCTAssertEqual(surface.timeString.value, "9:30 - 10am")
    }

    func testTimeRangeAfternoon() {
        let start = Calendar.current.todayAt(hour: 13, minute: 30)
        let end = Calendar.current.todayAt(hour: 14, minute: 15)
        let surface = EventSurface(mockData: ["startTime": start, "endTime": end])
        XCTAssertEqual(surface.timeString.value, "1:30 - 2:15pm")
    }

    func testTimeRangeMultiDay() {
        let start = Calendar.current.todayAt(hour: 13, minute: 30)
        let end = Calendar.current.date(byAdding: Calendar.Component.day, value: 1, to: start)!
        let surface = EventSurface(mockData: ["startTime": start, "endTime": end])
        XCTAssertEqual(surface.timeString.value, "1:30pm - 1:30pm (1 day later)")
    }

    func testTimeRangeMultiDay2() {
        let start = Calendar.current.todayAt(hour: 13, minute: 30)
        let end = Calendar.current.date(byAdding: Calendar.Component.day, value: 2, to: start)!
        let surface = EventSurface(mockData: ["startTime": start, "endTime": end])
        XCTAssertEqual(surface.timeString.value, "1:30pm - 1:30pm (2 days later)")
    }
}
