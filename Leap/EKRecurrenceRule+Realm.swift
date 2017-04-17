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



    func asSeries(_ tm: Temporality) -> Series {
        let data: ModelInitData = ["id": tm.id,
                                   "title": tm.title,
                                   "startTime": Int(tm.time),
                                   "endTime": recurrenceEnd?.endDate?.secondsSinceReferenceDate ?? 0]
        let series = Series(value: data)

        var templateData: ModelInitData = ["title": tm.title,
                                           "detail": tm.detail,
                                           "locationString": tm.locationString]
        if let event = tm as? Event {
            templateData["startHour"] = Calendar.current.component(.hour, from: event.startDate)
            templateData["startMinute"] = Calendar.current.component(.minute, from: event.startDate)
            templateData["modalityString"] = event.modalityString
        }
        series.template = Template(value: templateData)
        series.recurrence = asRecurrence()
        return series
    }

    func asRecurrence() -> Recurrence {
        let recurrence = Recurrence(value: ["frequencyRaw": getFrequency().rawValue,
                                            "interval": interval,
                                            "weekStartRaw": weekStart().rawValue,
                                            "count": recurrenceEnd?.occurrenceCount ?? 0])

        if let weekdays = daysOfTheWeek {
            weekdays.forEach { day in recurrence.daysOfWeek.append(recurrenceDay(from: day)) }
        }

        if let days = daysOfTheMonth {
            days.forEach { day in recurrence.daysOfMonth.append(IntWrapper.of(num: day)) }
        }

        if let days = daysOfTheYear {
            days.forEach { day in recurrence.daysOfYear.append(IntWrapper.of(num: day)) }
        }

        if let weeks = weeksOfTheYear {
            weeks.forEach { week in recurrence.weeksOfYear.append(IntWrapper.of(num: week)) }
        }

        if let months = monthsOfTheYear {
            months.forEach { month in recurrence.monthsOfYear.append(IntWrapper.of(num: month)) }
        }

        if let positions = setPositions {
            positions.forEach { pos in
                if Int(pos) <= 0 {
                    print("Position \(pos)")
                }
                recurrence.setPositions.append(IntWrapper.of(num: pos))
            }
        }
        
        return recurrence
    }
}
