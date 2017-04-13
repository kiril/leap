//
//  RecurrenceTests.swift
//  Leap
//
//  Created by Kiril Savino on 4/13/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
import Foundation

@testable import Leap

class RecurrenceTests: XCTestCase {

    var now = Date()
    var yesterday = Date()
    var series: Series = Series.series("Test Series", startingOn: Date())

    override func setUp() {
        yesterday = Calendar.current.date(byAdding: DateComponents(day: -1), to: now)!
        series = Series.series("Test Series", startingOn: yesterday)
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testEvery() {
        let rec = Recurrence.every(.daily, at: 0, past: 12)
        XCTAssertEqual(rec.frequency, Frequency.daily)
        XCTAssertEqual(rec.startHour, 12)
        XCTAssertEqual(rec.startMinute, 0)
        XCTAssertEqual(rec.count, 0)
    }
    
    func testTrivialDaily() {
        let rec = Recurrence.every(.daily, at: 30, past: 2)
        XCTAssertTrue(rec.recursOn(date: now, for: series))
    }

    func testOneDayOfWeek() {
        let rec = Recurrence.every(.daily, at: 30, past: 2)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .monday))

        let calendar = Calendar(identifier: .gregorian)
        var date = Date()
        while calendar.component(.weekday, from: date) != GregorianMonday {
            date = calendar.date(byAdding: DateComponents(day: 1), to: date)!
        }

        let monday = date
        XCTAssertTrue(rec.recursOn(date: monday, for: series))
        let tuesday = calendar.dayAfter(monday)
        XCTAssertFalse(rec.recursOn(date: tuesday, for: series))
        let wednesday = calendar.dayAfter(tuesday)
        XCTAssertFalse(rec.recursOn(date: wednesday, for: series))
        let thursday = calendar.dayAfter(wednesday)
        XCTAssertFalse(rec.recursOn(date: thursday, for: series))
    }

    func testMultipleDayOfWeek() {
        let rec = Recurrence.every(.daily, at: 30, past: 2)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .monday))
        rec.daysOfWeek.append(RecurrenceDay.of(day: .tuesday))

        let calendar = Calendar(identifier: .gregorian)
        var date = Date()
        while calendar.component(.weekday, from: date) != GregorianMonday {
            date = calendar.date(byAdding: DateComponents(day: 1), to: date)!
        }

        let monday = date
        XCTAssertTrue(rec.recursOn(date: monday, for: series))
        let tuesday = calendar.dayAfter(monday)
        XCTAssertTrue(rec.recursOn(date: tuesday, for: series))
        let wednesday = calendar.dayAfter(tuesday)
        XCTAssertFalse(rec.recursOn(date: wednesday, for: series))
        let thursday = calendar.dayAfter(wednesday)
        XCTAssertFalse(rec.recursOn(date: thursday, for: series))
        let friday = calendar.dayAfter(thursday)
        XCTAssertFalse(rec.recursOn(date: friday, for: series))
    }
}
