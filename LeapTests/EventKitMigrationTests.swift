//
//  EventKitMigrationTests.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
import RealmSwift
import EventKit
@testable import Leap

class EventKitMigrationTests: XCTestCase {
    var realm: Realm?
    
    override func setUp() {
        super.setUp()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "EventKitMigrationTest"))
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRecurrence() {
        let event = Event(value: ["id": "9999", "startDate": Date.secondsSinceReferenceDate, "endDate": Date.secondsSinceReferenceDate])
        let ek1 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.daily,
                                   interval: 1, end: EKRecurrenceEnd(occurrenceCount: 2))
        let r1: Recurrence = ek1.asRecurrence(on: event.startDate)
        XCTAssertEqual(r1.count, 2)
        XCTAssertEqual(r1.interval, 1)
        XCTAssertEqual(r1.frequency, Frequency.daily)

        let ek2 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.weekly,
                                   interval: 2, end: EKRecurrenceEnd(occurrenceCount: 1))
        let r2: Recurrence = ek2.asRecurrence(on: event.startDate)
        XCTAssertEqual(r2.count, 1)
        XCTAssertEqual(r2.interval, 2)
        XCTAssertEqual(r2.frequency, Frequency.weekly)

        let ek3 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.yearly, interval: 2, daysOfTheWeek: [EKRecurrenceDayOfWeek(EKWeekday.tuesday)], daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: [1 as NSNumber, -2 as NSNumber], daysOfTheYear: nil, setPositions: nil, end: nil)
        let r3: Recurrence = ek3.asRecurrence(on: event.startDate)

        XCTAssertEqual(r3.count, 0)
        XCTAssertEqual(r3.interval, 2)
        XCTAssertEqual(r3.frequency, Frequency.yearly)
        XCTAssertEqual(r3.daysOfWeek.count, 1)
        XCTAssertEqual(Weekday.from(gregorian: r3.daysOfWeek[0].raw), Weekday.tuesday)

        let endDate = Calendar.current.date(byAdding: DateComponents(year: 1), to: Date())!
        let ek4 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.weekly, interval: 1, daysOfTheWeek: [EKRecurrenceDayOfWeek(EKWeekday.tuesday), EKRecurrenceDayOfWeek(EKWeekday.thursday)], daysOfTheMonth: nil, monthsOfTheYear: [1 as NSNumber, 2 as NSNumber], weeksOfTheYear: nil, daysOfTheYear: nil, setPositions: nil, end: EKRecurrenceEnd(end: endDate))

        let store = EKEventStore()
        let ekCalendar = EKCalendar(for: EKEntityType.event, eventStore: store)
        let ekEvent = EKEvent(eventStore: store)
        ekEvent.startDate = Date()
        ekEvent.endDate = Date()
        let series = ek4.asSeries(for: ekEvent, in: ekCalendar)
        let r4 = series.recurrence!

        XCTAssertEqual(r4.count, 0)
        XCTAssertEqual(r4.interval, 1)
        XCTAssertEqual(r4.frequency, Frequency.weekly)
        XCTAssertEqual(r4.daysOfWeek.count, 2)
        XCTAssertEqual(Weekday.from(gregorian: r4.daysOfWeek[0].raw), Weekday.tuesday)
        XCTAssertEqual(Weekday.from(gregorian: r4.daysOfWeek[1].raw), Weekday.thursday)
        XCTAssertEqual(r4.monthsOfYear.count, 2)
        XCTAssertEqual(r4.monthsOfYear[0].raw, 1)
        XCTAssertEqual(r4.monthsOfYear[1].raw, 2)
        XCTAssertEqual(series.endTime, endDate.secondsSinceReferenceDate)
    }
    
}
