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

    func testMultipleDaysOfWeek() {
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

    func testTrivialMonthly() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9, on: 8)
        // need to make sure I get a real date, when not all days are valid in all months...
        let date = Calendar.current.date(byAdding: DateComponents(day: -1*(Calendar.current.component(.day, from: now)-1)), to: now)!
        XCTAssertTrue(rec.recursOn(date: date, for: series))
        let nextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: date)!
        XCTAssertTrue(rec.recursOn(date: nextMonth, for: series))
        let nextNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextMonth)!
        XCTAssertTrue(rec.recursOn(date: nextNextMonth, for: series))
    }

    func testEveryOtherMonth() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9, interval: 2, on: 8)
        // need to make sure I get a real date, when not all days are valid in all months...
        let date = Calendar.current.date(byAdding: DateComponents(day: -1*(Calendar.current.component(.day, from: now)-1)), to: now)!
        XCTAssertTrue(rec.recursOn(date: date, for: series))
        let nextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: date)!
        XCTAssertFalse(rec.recursOn(date: nextMonth, for: series))
        let nextNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextMonth)!
        XCTAssertTrue(rec.recursOn(date: nextNextMonth, for: series))
        let tripleNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextNextMonth)!
        XCTAssertFalse(rec.recursOn(date: tripleNextMonth, for: series))
    }
}
