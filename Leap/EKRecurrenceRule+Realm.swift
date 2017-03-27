//
//  EKRecurrenceRule+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

/*
Recurrence:

 dynamic var startTime: Date?
 dynamic var endTime: Date?
 dynamic var leadTime: Double = 0.0
 dynamic var trailTime: Double = 0.0
 dynamic var count: Int = 0
 dynamic var frequencyString: String = Frequency.unknown.rawValue
 dynamic var interval: Int = 0
 dynamic var referenceEvent: Event?
 */

/*
 EKRecurrence:
 .calendarIdentifier
 .recurrenceEnd -> EKRecurrenceEnd? ->
 .frequency -> EKRecurrenceFrequency
 .interval -> Int
 .firstDayOfTheWeek -> Int (and Fuck You, btw, someone somewhere)
 .daysOfTheWeek -> [EKRecurrenceDayOfWeek]? ->
 .daysOfTheMonth -> [NSNumber]?
 .daysOfTheYear -> [NSNumber]?
 .weeksOfTheYear -> [NSNumber]?
 .monthsOfTheYear -> [NSNumber]?
 .setPositions -> [NSNumber]? (allowed recurrances in total, negative allowed... damn...)
 */

extension EKRecurrenceRule {
    func toRecurrence() -> Recurrence {
        
    }
}
