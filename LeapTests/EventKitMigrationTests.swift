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
        let ek1 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.daily,
                                   interval: 1, end: EKRecurrenceEnd(occurrenceCount: 2))
        let r1: Recurrence = ek1.asRecurrence()
        XCTAssertEqual(r1.count, 2)
        XCTAssertEqual(r1.interval, 1)
        XCTAssertEqual(r1.frequency, Frequency.daily)

        let ek2 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.weekly,
                                   interval: 2, end: EKRecurrenceEnd(occurrenceCount: 1))
        let r2: Recurrence = ek2.asRecurrence()
        XCTAssertEqual(r2.count, 1)
        XCTAssertEqual(r2.interval, 2)
        XCTAssertEqual(r2.frequency, Frequency.weekly)

        let ek3 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.yearly, interval: 2, daysOfTheWeek: [EKRecurrenceDayOfWeek(EKWeekday.tuesday)], daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: [1 as NSNumber, -2 as NSNumber], daysOfTheYear: nil, setPositions: nil, end: nil)
        let r3 = ek3.asRecurrence()

        XCTAssertEqual(r3.count, 0)
        XCTAssertEqual(r3.interval, 2)
        XCTAssertEqual(r3.frequency, Frequency.yearly)
        XCTAssertEqual(r3.daysOfWeek.count, 1)
        XCTAssertEqual(r3.daysOfWeek[0].dayOfWeek, DayOfWeek.tuesday)

        let endDate = Calendar.current.date(byAdding: DateComponents(year: 1), to: Date())!
        let ek4 = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.weekly, interval: 1, daysOfTheWeek: [EKRecurrenceDayOfWeek(EKWeekday.tuesday), EKRecurrenceDayOfWeek(EKWeekday.thursday)], daysOfTheMonth: nil, monthsOfTheYear: [1 as NSNumber, 2 as NSNumber], weeksOfTheYear: nil, daysOfTheYear: nil, setPositions: nil, end: EKRecurrenceEnd(end: endDate))
        let r4 = ek4.asRecurrence()

        XCTAssertEqual(r4.count, 0)
        XCTAssertEqual(r4.interval, 1)
        XCTAssertEqual(r4.frequency, Frequency.weekly)
        XCTAssertEqual(r4.daysOfWeek.count, 2)
        XCTAssertEqual(r4.daysOfWeek[0].dayOfWeek, DayOfWeek.tuesday)
        XCTAssertEqual(r4.daysOfWeek[1].dayOfWeek, DayOfWeek.thursday)
        XCTAssertEqual(r4.monthsOfYear.count, 2)
        XCTAssertEqual(r4.monthsOfYear[0].value, 1)
        XCTAssertEqual(r4.monthsOfYear[1].value, 2)
        XCTAssertEqual(Int(r4.endTime!.timeIntervalSince1970), Int(endDate.timeIntervalSince1970)) // weird that comparing dates directly doesn't work
    }

    func testParticipants() {
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
