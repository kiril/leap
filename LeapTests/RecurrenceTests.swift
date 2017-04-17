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

    let calendar = Calendar(identifier: .gregorian)
    var now = Date()
    var yesterday = Date()
    var series: Series = Series.series("Test Series", startingOn: Date())

    override func setUp() {
        yesterday = calendar.date(byAdding: DateComponents(day: -1), to: now)!
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
        XCTAssertTrue(rec.recursOn(now, for: series))
    }

    func testOneDayOfWeek() {
        let rec = Recurrence.every(.daily, at: 30, past: 2)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .monday))

        let monday = calendar.theNext(weekday: GregorianMonday, onOrAfter: now)

        XCTAssertTrue(rec.recursOn(monday, for: series))
        let tuesday = calendar.dayAfter(monday)
        XCTAssertFalse(rec.recursOn(tuesday, for: series))
        let wednesday = calendar.dayAfter(tuesday)
        XCTAssertFalse(rec.recursOn(wednesday, for: series))
        let thursday = calendar.dayAfter(wednesday)
        XCTAssertFalse(rec.recursOn(thursday, for: series))
    }

    func testMultipleDaysOfWeek() {
        let rec = Recurrence.every(.daily, at: 30, past: 2)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .monday))
        rec.daysOfWeek.append(RecurrenceDay.of(day: .tuesday))

        let monday = calendar.theNext(weekday: GregorianMonday, onOrAfter: now)

        XCTAssertTrue(rec.recursOn(monday, for: series))
        let tuesday = calendar.dayAfter(monday)
        XCTAssertTrue(rec.recursOn(tuesday, for: series))
        let wednesday = calendar.dayAfter(tuesday)
        XCTAssertFalse(rec.recursOn(wednesday, for: series))
        let thursday = calendar.dayAfter(wednesday)
        XCTAssertFalse(rec.recursOn(thursday, for: series))
        let friday = calendar.dayAfter(thursday)
        XCTAssertFalse(rec.recursOn(friday, for: series))
    }

    func testTrivialMonthly() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9, on: 8)
        // need to make sure I get a real date, when not all days are valid in all months...
        let date = Calendar.current.date(byAdding: DateComponents(day: -1*(Calendar.current.component(.day, from: now)-1)), to: now)!
        XCTAssertTrue(rec.recursOn(date, for: series))
        let nextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: date)!
        XCTAssertTrue(rec.recursOn(nextMonth, for: series))
        let nextNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextMonth)!
        XCTAssertTrue(rec.recursOn(nextNextMonth, for: series))
    }

    func testEveryOtherMonth() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9, interval: 2, on: 8)
        // need to make sure I get a real date, when not all days are valid in all months...
        let date = Calendar.current.date(byAdding: DateComponents(day: -1*(Calendar.current.component(.day, from: now)-1)), to: now)!
        XCTAssertTrue(rec.recursOn(date, for: series))
        let nextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: date)!
        XCTAssertFalse(rec.recursOn(nextMonth, for: series))
        let nextNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextMonth)!
        XCTAssertTrue(rec.recursOn(nextNextMonth, for: series))
        let tripleNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextNextMonth)!
        XCTAssertFalse(rec.recursOn(tripleNextMonth, for: series))
    }

    func testFirstTuesdayOfMonth() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9)
        rec.daysOfWeek.append(RecurrenceDay.of(day: DayOfWeek.tuesday, in: 1))

        let theFirst = calendar.startOfMonth(onOrAfter: now)
        let firstTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: theFirst)
        XCTAssertTrue(rec.recursOn(firstTuesday, for: series), "Didn't recur on \(firstTuesday)")
        let secondTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: calendar.dayAfter(firstTuesday))
        XCTAssertFalse(rec.recursOn(secondTuesday, for: series))
    }

    func testSecondTuesdayOfMonth() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9)
        rec.daysOfWeek.append(RecurrenceDay.of(day: DayOfWeek.tuesday, in: 2))

        let theFirst = calendar.startOfMonth(onOrAfter: now)
        let firstTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: theFirst)
        XCTAssertFalse(rec.recursOn(firstTuesday, for: series), "Didn't recur on \(firstTuesday)")
        let secondTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: calendar.dayAfter(firstTuesday))
        XCTAssertTrue(rec.recursOn(secondTuesday, for: series))
    }

    func testSundaysInFebruary() {
        let rec = Recurrence.every(.weekly, at: 0, past: 9)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .sunday))
        rec.monthsOfYear.append(IntWrapper.of(2))

        let theFirst = calendar.startOfMonth(onOrAfter: now)
        let feb1 = calendar.date(bySetting: .month, value: 2, of: theFirst)!
        let jan1 = calendar.date(byAdding: .month, value: -1, to: feb1)!
        let mar1 = calendar.date(byAdding: .month, value: 1, to: feb1)!

        XCTAssertEqual(calendar.component(.month, from: feb1), 2)

        for sunday in calendar.all(weekdays: GregorianSunday, inMonthOf: feb1) {
            XCTAssertTrue(rec.recursOn(sunday, for: series))
        }

        for sunday in calendar.all(weekdays: GregorianSunday, inMonthOf: mar1) {
            XCTAssertFalse(rec.recursOn(sunday, for: series))
        }

        for sunday in calendar.all(weekdays: GregorianSunday, inMonthOf: jan1) {
            XCTAssertFalse(rec.recursOn(sunday, for: series))
        }
    }

    func testPositionalInMonth() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .friday))
        rec.setPositions.append(IntWrapper.of(2))

        let fridays = calendar.all(weekdays: GregorianFriday, inMonthOf: now)
        XCTAssertFalse(rec.recursOn(fridays[0], for: series))
        XCTAssertTrue(rec.recursOn(fridays[1], for: series))
        for friday in fridays.dropFirst(2) {
            XCTAssertFalse(rec.recursOn(friday, for: series))
        }
    }

    func testComplexPositionalInMonth() {
        let rec = Recurrence.every(.monthly, at: 0, past: 9)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .thursday))
        rec.daysOfWeek.append(RecurrenceDay.of(day: .friday))
        rec.setPositions.append(IntWrapper.of(2))

        let startOfMonth = calendar.startOfMonth(onOrAfter: now)

        var matchCount = 0
        for day in calendar.allDays(inMonthOf: startOfMonth) {
            let weekday = calendar.component(.weekday, from: day)
            if weekday == GregorianThursday || weekday == GregorianFriday {
                matchCount += 1
                if matchCount == 2 {
                    XCTAssertTrue(rec.recursOn(day, for: series))
                } else {
                    XCTAssertFalse(rec.recursOn(day, for: series))
                }
            }
        }
    }

    func testPositionalInYear() {
        let rec = Recurrence.every(.yearly, at: 0, past: 9)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .saturday))
        rec.setPositions.append(IntWrapper.of(3))

        let saturdays = calendar.all(weekdays: GregorianSaturday, inYearOf: now)
        XCTAssertFalse(rec.recursOn(saturdays[0], for: series))
        XCTAssertFalse(rec.recursOn(saturdays[1], for: series))
        XCTAssertTrue(rec.recursOn(saturdays[2], for: series))
        for saturday in saturdays.dropFirst(3) {
            XCTAssertFalse(rec.recursOn(saturday, for: series), "\(saturday)")
        }
    }

    func testSecondAndLastWeekdayInYear() {
        let rec = Recurrence.every(.yearly, at: 0, past: 9)
        rec.daysOfWeek.append(RecurrenceDay.of(day: .monday))
        rec.daysOfWeek.append(RecurrenceDay.of(day: .tuesday))
        rec.daysOfWeek.append(RecurrenceDay.of(day: .wednesday))
        rec.daysOfWeek.append(RecurrenceDay.of(day: .thursday))
        rec.daysOfWeek.append(RecurrenceDay.of(day: .friday))
        rec.setPositions.append(IntWrapper.of(2))
        rec.setPositions.append(IntWrapper.of(-1))

        let startOfYear = calendar.startOfYear(onOrAfter: now)

        let days = calendar.allDays(inYearOf: startOfYear)

        var finalWeekdayIndex = 0
        for (i, day) in days.reversed().enumerated() {
            if calendar.isWeekday(day) {
                finalWeekdayIndex = days.count - i - 1
                break
            }
        }
        assert(finalWeekdayIndex != 0)

        var matchCount = 0
        for (i, day) in days.enumerated() {
            if calendar.isWeekday(day) {
                if i == finalWeekdayIndex {
                    XCTAssertTrue(rec.recursOn(day, for: self.series))
                } else {
                    matchCount += 1
                    if matchCount == 2 {
                        XCTAssertTrue(rec.recursOn(day, for: self.series))
                    } else {
                        XCTAssertFalse(rec.recursOn(day, for: self.series))
                    }
                }
            }
        }
    }
}
