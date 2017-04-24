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
 .recurrenceEnd -> EKRecurrenceEnd? -> .endDate or .occurrenceCount (0 if date-based)
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
    func getFrequency() -> Frequency {
        switch self.frequency {
        case .daily:
            return Frequency.daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        }
    }

    func weekStart() -> DayOfWeek {
        switch firstDayOfTheWeek {
        case 0: // unset onthis rule, so default to Sunday
            return .sunday
        default:
            return DayOfWeek(rawValue: firstDayOfTheWeek)! // defined to be 1-7
        }
    }

    func recurrenceDay(from dow: EKRecurrenceDayOfWeek) -> RecurrenceDay {
        let day: DayOfWeek = DayOfWeek(rawValue: dow.dayOfTheWeek.rawValue) ?? .sunday
        return RecurrenceDay.of(day: day, in: dow.weekNumber)
    }


    func asSeries(for event: EKEvent, in calendar: EKCalendar) -> Series {
        let data: ModelInitData = ["id": event.cleanId,
                                   "title": event.title,
                                   "startTime": event.startDate.secondsSinceReferenceDate,
                                   "typeString": event.type.rawValue,
                                   "endTime": recurrenceEnd?.endDate?.secondsSinceReferenceDate ?? 0,
                                   "originString": event.origin.rawValue,
                                   "template": event.asTemplate(),
                                   "recurrence": self.asRecurrence(for: event)]
        return Series(value: data)
    }

    func asRecurrence(for event: EKEvent) -> Recurrence {
        let recurrence = Recurrence(value: ["frequencyRaw": getFrequency().rawValue,
                                            "interval": interval,
                                            "weekStartRaw": weekStart().rawValue,
                                            "count": recurrenceEnd?.occurrenceCount ?? 0])

        if let weekdays = daysOfTheWeek {
            weekdays.forEach { recurrence.daysOfWeek.append(recurrenceDay(from: $0)) }

        } else if getFrequency() == .weekly {
            recurrence.daysOfWeek.append(RecurrenceDay.of(day: DayOfWeek.from(date: event.startDate)))
        }

        if let days = daysOfTheMonth {
            days.forEach { recurrence.daysOfMonth.append(Int($0)) }
        }

        if let days = daysOfTheYear {
            days.forEach { recurrence.daysOfYear.append(Int($0)) }
        }

        if let weeks = weeksOfTheYear {
            weeks.forEach { recurrence.weeksOfYear.append(Int($0)) }
        }

        if let months = monthsOfTheYear {
            months.forEach { recurrence.monthsOfYear.append(Int($0)) }
        }

        if let positions = setPositions {
            positions.forEach { recurrence.setPositions.append(Int($0)) }
        }
        
        return recurrence
    }
}
