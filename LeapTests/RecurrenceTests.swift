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
        let rec = Recurrence.every(.daily)
        XCTAssertEqual(rec.frequency, Frequency.daily)
        XCTAssertEqual(rec.count, 0)
    }
    
    func testTrivialDaily() {
        let rec = Recurrence.every(.daily)
        XCTAssertTrue(rec.recurs(on: now, for: series))
    }

    func testOneDayOfWeek() {
        let rec = Recurrence.every(.daily)
        rec.daysOfWeek.append(.monday)

        let monday = calendar.theNext(weekday: GregorianMonday, onOrAfter: now)

        XCTAssertTrue(rec.recurs(on: monday, for: series))
        let tuesday = calendar.dayAfter(monday)
        XCTAssertFalse(rec.recurs(on: tuesday, for: series))
        let wednesday = calendar.dayAfter(tuesday)
        XCTAssertFalse(rec.recurs(on: wednesday, for: series))
        let thursday = calendar.dayAfter(wednesday)
        XCTAssertFalse(rec.recurs(on: thursday, for: series))
    }

    func testMultipleDaysOfWeek() {
        let rec = Recurrence.every(.daily)
        rec.daysOfWeek.append(.monday)
        rec.daysOfWeek.append(.tuesday)

        let monday = calendar.theNext(weekday: GregorianMonday, onOrAfter: now)

        XCTAssertTrue(rec.recurs(on: monday, for: series))
        let tuesday = calendar.dayAfter(monday)
        XCTAssertTrue(rec.recurs(on: tuesday, for: series))
        let wednesday = calendar.dayAfter(tuesday)
        XCTAssertFalse(rec.recurs(on: wednesday, for: series))
        let thursday = calendar.dayAfter(wednesday)
        XCTAssertFalse(rec.recurs(on: thursday, for: series))
        let friday = calendar.dayAfter(thursday)
        XCTAssertFalse(rec.recurs(on: friday, for: series))
    }

    func testTrivialMonthly() {
        let rec = Recurrence.every(.monthly, the: 1)

        // need to make sure I get a real date, when not all days are valid in all months...
        let date = Calendar.current.date(byAdding: DateComponents(day: -1*(Calendar.current.component(.day, from: now)-1)), to: now)!
        XCTAssertTrue(rec.recurs(on: date, for: series))
        let nextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: date)!
        XCTAssertTrue(rec.recurs(on: nextMonth, for: series))
        let nextNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextMonth)!
        XCTAssertTrue(rec.recurs(on: nextNextMonth, for: series))
    }

    func testEveryOtherMonth() {
        let rec = Recurrence.every(.monthly, by: 2, the: 1)
        let date = Calendar.current.startOfMonth(including: now)
        XCTAssertTrue(rec.recurs(on: date, for: series))

        let nextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: date)!
        XCTAssertFalse(rec.recurs(on: nextMonth, for: series))

        let nextNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextMonth)!
        XCTAssertTrue(rec.recurs(on: nextNextMonth, for: series))

        let tripleNextMonth = Calendar.current.date(byAdding: DateComponents(month: 1), to: nextNextMonth)!
        XCTAssertFalse(rec.recurs(on: tripleNextMonth, for: series))
    }

    func testFirstTuesdayOfMonth() {
        let rec = Recurrence.every(.monthly)
        rec.daysOfWeek.append(Weekday.tuesday.week(1))

        let theFirst = calendar.startOfMonth(onOrAfter: now)
        let firstTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: theFirst)
        XCTAssertTrue(rec.recurs(on: firstTuesday, for: series), "Didn't recur on \(firstTuesday)")
        let secondTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: calendar.dayAfter(firstTuesday))
        XCTAssertFalse(rec.recurs(on: secondTuesday, for: series))
    }

    func testSecondTuesdayOfMonth() {
        let rec = Recurrence.every(.monthly)
        rec.daysOfWeek.append(Weekday.tuesday.week(2))

        let theFirst = calendar.startOfMonth(onOrAfter: now)
        let firstTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: theFirst)
        XCTAssertFalse(rec.recurs(on: firstTuesday, for: series), "Didn't recur on \(firstTuesday)")
        let secondTuesday = calendar.theNext(weekday: GregorianTuesday, onOrAfter: calendar.dayAfter(firstTuesday))
        XCTAssertTrue(rec.recurs(on: secondTuesday, for: series))
    }

    func testSundaysInFebruary() {
        let rec = Recurrence.every(.weekly)
        rec.daysOfWeek.append(.sunday)
        rec.monthsOfYear.append(2)

        let theFirst = calendar.startOfMonth(onOrAfter: now)
        let feb1 = calendar.date(bySetting: .month, value: 2, of: theFirst)!
        let jan1 = calendar.date(byAdding: .month, value: -1, to: feb1)!
        let mar1 = calendar.date(byAdding: .month, value: 1, to: feb1)!

        XCTAssertEqual(calendar.component(.month, from: feb1), 2)

        for sunday in calendar.all(weekdays: GregorianSunday, inMonthOf: feb1) {
            XCTAssertTrue(rec.recurs(on: sunday, for: series))
        }

        for sunday in calendar.all(weekdays: GregorianSunday, inMonthOf: mar1) {
            XCTAssertFalse(rec.recurs(on: sunday, for: series))
        }

        for sunday in calendar.all(weekdays: GregorianSunday, inMonthOf: jan1) {
            XCTAssertFalse(rec.recurs(on: sunday, for: series))
        }
    }

    func testPositionalInMonth() {
        self.measure {
            let rec = Recurrence.every(.monthly)
            rec.daysOfWeek.append(.friday)
            rec.setPositions.append(2)

            let fridays = self.calendar.all(weekdays: GregorianFriday, inMonthOf: self.now)
            XCTAssertFalse(rec.recurs(on: fridays[0], for: self.series))
            XCTAssertTrue(rec.recurs(on: fridays[1], for: self.series))
            for friday in fridays.dropFirst(2) {
                XCTAssertFalse(rec.recurs(on: friday, for: self.series))
            }
        }
    }

    func testComplexPositionalInMonth() {
        let rec = Recurrence.every(.monthly)
        rec.daysOfWeek.append(.thursday)
        rec.daysOfWeek.append(.friday)
        rec.setPositions.append(2)

        let startOfMonth = calendar.startOfMonth(onOrAfter: now)

        var matchCount = 0
        for day in calendar.allDays(inMonthOf: startOfMonth) {
            let weekday = calendar.component(.weekday, from: day)
            if weekday == GregorianThursday || weekday == GregorianFriday {
                matchCount += 1
                if matchCount == 2 {
                    XCTAssertTrue(rec.recurs(on: day, for: series))
                } else {
                    XCTAssertFalse(rec.recurs(on: day, for: series))
                }
            }
        }
    }

    func testPositionalInYear() {
        let rec = Recurrence.every(.yearly)
        rec.daysOfWeek.append(.saturday)
        rec.setPositions.append(3)

        let saturdays = calendar.all(weekdays: GregorianSaturday, inYearOf: now)
        XCTAssertFalse(rec.recurs(on: saturdays[0], for: series))
        XCTAssertFalse(rec.recurs(on: saturdays[1], for: series))
        XCTAssertTrue(rec.recurs(on: saturdays[2], for: series))
        for saturday in saturdays.dropFirst(3) {
            XCTAssertFalse(rec.recurs(on: saturday, for: series), "\(saturday)")
        }
    }

    func testDayOfWeek() {
        XCTAssertEqual(Weekday.sunday.rawValue, 1)
        XCTAssertEqual(Weekday.sunday.week(1).encode(), 1001)
        XCTAssertEqual(Weekday.sunday.week(-2).encode(), -2001)

        XCTAssertEqual(OrdinalWeekday.decode(-2001).weekday, Weekday.sunday)
        XCTAssertEqual(OrdinalWeekday.decode(1001).weekday, Weekday.sunday)
        XCTAssertEqual(OrdinalWeekday.decode(1).weekday, Weekday.sunday)
    }

    func testDayOfWeekMatches() {
        let rec = Recurrence.every(.yearly)
        rec.daysOfWeek.append(.saturday)

        XCTAssertTrue(rec.dayOfWeekMatches(for: calendar.theNext(.saturday, after: Date())))
    }

    func testSecondAndLastWeekdayInYear() {
        self.measure {
            let rec = Recurrence.every(.yearly)
            rec.daysOfWeek.append(.monday)
            rec.daysOfWeek.append(.tuesday)
            rec.daysOfWeek.append(.wednesday)
            rec.daysOfWeek.append(.thursday)
            rec.daysOfWeek.append(.friday)
            rec.setPositions.append(2)
            rec.setPositions.append(-1)

            let startOfYear = self.calendar.startOfYear(onOrAfter: self.now)
            let daysInFebruary = self.calendar.range(of: .day, in: .month, for: self.calendar.date(bySetting: .month, value: 2, of: startOfYear)!)!.upperBound - 1
            let daysInYear = 365 + (daysInFebruary - 28)

            var finalWeekdayIndex = 0
            var i = 0
            for day in self.calendar.allDaysReversed(inYearOf: startOfYear) {
                if self.calendar.isWeekday(day) {
                    finalWeekdayIndex = daysInYear - i - 1
                    break
                }
                i += 1
            }
            assert(finalWeekdayIndex != 0)

            var matchCount = 0
            i = 0
            for day in self.calendar.allDays(inYearOf: startOfYear) {
                if self.calendar.isWeekday(day) {
                    if i == finalWeekdayIndex {
                        XCTAssertTrue(rec.recurs(on: day, for: self.series))
                    } else {
                        matchCount += 1
                        if matchCount == 2 {
                            XCTAssertTrue(rec.recurs(on: day, for: self.series))
                        } else {
                            XCTAssertFalse(rec.recurs(on: day, for: self.series))
                        }
                    }
                }
                i += 1
            }
        }
    }

    func testEveryOtherWeekendLongEvent() {
        let lastFriday = Calendar.current.theLast(.friday, before: now)

        let series = Series.series("Weekend Event", startingOn: lastFriday)
        series.recurrence = Recurrence.every(.weekly, by: 2, on: .friday)
        series.template = Template.of("Weekend Event", at: 0, past: 18, lasting: 1200)

        XCTAssertTrue(series.recurs(on: lastFriday))

        let nextFriday = Calendar.current.theNext(.friday, after: lastFriday)
        XCTAssertTrue(nextFriday > lastFriday)
        XCTAssertEqual(7, Calendar.current.daysBetween(lastFriday, and: nextFriday))
        print("TESTING NOW on \(nextFriday) with a start of \(lastFriday)")
        XCTAssertFalse(series.recurs(on: nextFriday))
    }
}
