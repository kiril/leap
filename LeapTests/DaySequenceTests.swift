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
        let tomorrow = forward.day(after: now)!
        XCTAssertEqual(1, calendar.daysBetween(now, and: tomorrow))
        let next = forward.day(after: tomorrow)!
        XCTAssertEqual(2, calendar.daysBetween(now, and: next))
        let yesterday = forward.day(before: now)!
        XCTAssertEqual(-1, calendar.daysBetween(now, and: yesterday))
        let earlier = forward.day(before: yesterday)!
        XCTAssertEqual(-2, calendar.daysBetween(now, and: earlier))
    }

    func testDorsalTraversalReversalForecastle() {
        let forward = CalendarDayTraversal(calendar).reversed()
        let tomorrow = forward.day(before: now)!
        XCTAssertEqual(1, calendar.daysBetween(now, and: tomorrow))
        let next = forward.day(before: tomorrow)!
        XCTAssertEqual(2, calendar.daysBetween(now, and: next))

        let yesterday = forward.day(after: now)!
        XCTAssertEqual(-1, calendar.daysBetween(now, and: yesterday))
        let earlier = forward.day(after: yesterday)!
        XCTAssertEqual(-2, calendar.daysBetween(now, and: earlier))
    }

    func testMonthBoundDayTraversal() {
        let start = calendar.startOfMonth(including: now)
        let month = calendar.component(.month, from: start)
        let year = calendar.component(.year, from: start)
        let t = MonthBoundDayTraversal(using: calendar, in: month, of: year)

        var days = 0
        var d = start
        while let day = t.day(after: d) {
            days += 1
            XCTAssertEqual(month, calendar.component(.month, from: day), "Jumped month on day #\(days)")
            XCTAssertEqual(year, calendar.component(.year, from: day))
            XCTAssertTrue(days < 32, "Shit, not bound")
            d = day
        }
        XCTAssertTrue(days >= 27, "Not complete")
    }

    func testBackwardMonthBoundSequence() {
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        let days = DaySequence.month(of: now, using: calendar, reversed: true)

        var count = 0
        var last: Date? = nil
        for day in days {
            count += 1
            XCTAssertEqual(month, calendar.component(.month, from: day), "Jumped month on day #\(count)")
            XCTAssertEqual(year, calendar.component(.year, from: day))
            XCTAssertTrue(count < 32)
            if let last = last {
                XCTAssertTrue(day < last)
            }
            last = day
        }
        XCTAssertTrue(count >= 27, "Not complete")
    }

    func testYearBoundDayTraversal() {
        let start = calendar.startOfYear(including: now)
        let year = calendar.component(.year, from: start)
        let t = YearBoundDayTraversal(using: calendar, of: year)

        var days = 0
        var d = start
        while let day = t.day(after: d) {
            days += 1
            XCTAssertEqual(year, calendar.component(.year, from: day))
            XCTAssertTrue(days < 366, "Shit, not bound")
            d = day
        }
        XCTAssertTrue(days >= 27, "Not complete")
    }

    func testBackwardYearBoundDayTraversal() {
        let start = calendar.endOfYear(including: now)
        let year = calendar.component(.year, from: start)
        let t = YearBoundDayTraversal(using: calendar, of: year).reversed()

        var days = 0
        var d = start
        while let day = t.day(after: d) {
            days += 1
            XCTAssertEqual(year, calendar.component(.year, from: day))
            XCTAssertTrue(days < 366, "Shit, not bound")
            d = day
        }
        XCTAssertTrue(days >= 27, "Not complete")
    }

    func testWeekdayTraversal() {
        let days = DaySequence.weekdays(startingAt: now, using: calendar, max: 7)
        var count = 0
        for day in days {
            count += 1
            XCTAssertTrue(calendar.isWeekday(day))
        }
        XCTAssertTrue(count == 7)
    }

    func testCustomWeekdayTraversal() {
        let weekday = calendar.component(.weekday, from: now)
        let days = DaySequence.weekdays(startingAt: now, using: calendar, weekdays: [weekday], max: 7)
        var count = 0
        for day in days {
            count += 1
            XCTAssertTrue(calendar.isWeekday(day))
            XCTAssertEqual(weekday, calendar.component(.weekday, from: day))
            XCTAssertEqual(7*(count-1), calendar.daysBetween(now, and: day), "\(day) is \(calendar.daysBetween(now, and: day)) after \(now)")
        }
        XCTAssertTrue(count == 7)
    }

    func testCustomWeekdayTraversal2() {
        let weekday = ((calendar.component(.weekday, from: now) + 1) % 7) + 1
        let another = ((weekday + 1) % 7) + 1
        let weekdays = [weekday, another]
        let days = DaySequence.weekdays(startingAt: now, using: calendar, weekdays: weekdays, max: 7)
        var count = 0
        var found1 = false
        var found2 = false
        var last: Date? = nil
        for day in days {
            count += 1
            let w = calendar.component(.weekday, from: day)
            if day != now {
                XCTAssertTrue(weekdays.contains(w), "\(weekdays) [\(weekdays.map({Weekday.name(of:$0)}))] doesn't contain \(w) [\(Weekday.name(of: w))]")
            }
            if w == weekday {
                found1 = true
            } else if w == another {
                found2 = true
            }
            if let last = last {
                XCTAssertTrue(last < day)
            }
            last = day
        }
        XCTAssertTrue(count == 7)
        XCTAssertTrue(found1)
        XCTAssertTrue(found2)
    }

    func testMonthlyTraversal() {
    }
    
}
