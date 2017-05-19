//
//  DaySequenceTests.swift
//  Leap
//
//  Created by Kiril Savino on 5/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
@testable import Leap

class DaySequenceTests: XCTestCase {

    let now: Date = Date()
    var calendar: Calendar { return Calendar.current }

    func testCalendarDayTraversal() {
        let forward = CalendarDayTraversal(calendar)
        let tomorrow = forward.day(after: now)
        XCTAssertEqual(1, calendar.daysBetween(now, and: tomorrow))
        let next = forward.day(after: tomorrow)
        XCTAssertEqual(2, calendar.daysBetween(now, and: next))
        let yesterday = forward.day(before now)
        XCTAssertEqual(-1, calendar.daysBetween(now, and: yesterday))
        let earlier = forward.day(before: yesterday)
        XCTAssertEqual(-2, calendar.daysBetween(now, and: earler))
    }

    func testWeekdayTraversal() {
    }

    func testMonthlyTraversal() {
    }

    func testTraveralReversalRehearsal() {
    }
    
}
