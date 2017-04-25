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

    let calendar = Calendar(identifier: .gregorian)
    let now = Date()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFormatDisplayTimeAM() {
        let components = DateComponents(calendar: calendar, hour: 9, minute: 5)
        let date = calendar.date(from: components)!
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: false), "9:05")
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: true), "9:05am")
    }

    func testFormatDisplayTimePM() {
        let components = DateComponents(calendar: calendar, hour: 21, minute: 5)
        let date = calendar.date(from: components)!
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: false), "9:05")
        XCTAssertEqual(calendar.formatDisplayTime(from: date, needsAMPM: true), "9:05pm")
    }

    func testConvenientComparison() {
        let a = calendar.todayAt(hour: 9, minute: 0)
        let b = calendar.todayAt(hour: 10, minute: 0)
        XCTAssertTrue(calendar.isDate(a, before: b))
        XCTAssertTrue(calendar.isDate(b, after: a))


        let c = calendar.todayAt(hour: 9, minute: 0)
        let d = calendar.todayAt(hour: 9, minute: 0)
        XCTAssertFalse(calendar.isDate(c, before: d))
        XCTAssertFalse(calendar.isDate(c, after: d))


        let e = calendar.todayAt(hour: 9, minute: 0)
        let f = calendar.todayAt(hour: 9, minute: 1)
        XCTAssertTrue(calendar.isDate(e, before: f))
        XCTAssertTrue(calendar.isDate(f, after: e))
    }

    func testDayAfter() {
        let theFirst = calendar.date(bySetting: .day, value: 1, of: now)!
        let theSecond = calendar.dayAfter(theFirst)
        XCTAssertEqual(calendar.component(.day, from: theFirst), 1)
        XCTAssertEqual(calendar.component(.day, from: theSecond), 2)
        XCTAssertEqual(calendar.component(.month, from: theFirst), calendar.component(.month, from: theSecond))
        XCTAssertEqual(calendar.component(.year, from: theFirst), calendar.component(.year, from: theSecond))
    }

    func testNextWeekday() {
        let firstTuesday = calendar.theNext(weekday: GregorianTuesday, after: now)
        XCTAssertEqual(calendar.component(.weekday, from: firstTuesday), GregorianTuesday)
        let sameTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: firstTuesday)
        XCTAssertEqual(firstTuesday, sameTuesday)
        let anotherTuesday = calendar.theNext(weekday: GregorianTuesday, after: firstTuesday)
        XCTAssertNotEqual(firstTuesday, anotherTuesday)
        XCTAssertEqual(calendar.component(.weekday, from: anotherTuesday), GregorianTuesday)
        XCTAssertTrue(calendar.isDate(anotherTuesday, after: firstTuesday))
    }

    func testTheFirst() {
        let theFirst = calendar.startOfMonth(onOrAfter: now)
        XCTAssertEqual(calendar.component(.day, from: theFirst), 1)
    }

    func testAllWeekdays() {
        let theFirst = calendar.date(bySetting: .day, value: 1, of: now)!
        XCTAssertEqual(calendar.component(.day, from: theFirst), 1)
        let wednesdays = calendar.all(weekdays: GregorianWednesday, inMonthOf: theFirst)
        XCTAssertTrue(wednesdays.count >= 4 && wednesdays.count <= 5)
        for wednesday in wednesdays {
            XCTAssertEqual(calendar.component(.weekday, from: wednesday), GregorianWednesday)
        }
    }

    func testWeekdayOrdinal() {
        let components = DateComponents(year: 2017, month: 1, day: 1)
        let januaryFirst2017 = calendar.date(from: components)!
        XCTAssertEqual(calendar.component(.weekday, from: januaryFirst2017), GregorianSunday)
        XCTAssertEqual(calendar.weekdayOrdinal(of: januaryFirst2017), 1)
        XCTAssertEqual(calendar.count(weekday: GregorianSunday, inMonthOf: januaryFirst2017), 5)


        let aprilComponents = DateComponents(year: 2017, month: 4, day: 10)
        let aprilTenth2017 = calendar.date(from: aprilComponents)!
        XCTAssertEqual(calendar.component(.weekday, from: aprilTenth2017), GregorianMonday)
        XCTAssertEqual(calendar.weekdayOrdinal(of: aprilTenth2017), 2)
        XCTAssertEqual(calendar.count(weekday: GregorianMonday, inMonthOf: aprilTenth2017), 4)
    }

    func testNegativeOrdinal() {
        XCTAssertEqual(calendar.negativeOrdinal(ordinal: 3, total: 4), -2)
        XCTAssertEqual(calendar.negativeOrdinal(ordinal: 4, total: 4), -1)
        XCTAssertEqual(calendar.negativeOrdinal(ordinal: 1, total: 5), -5)
    }
    //func count(weekday: Int, inMonthOf date: Date) -> Int {
    //func negativeOrdinal(ordinal: Int, total: Int) -> Int {
}
