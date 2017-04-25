//
//  EKRecurrenceRule+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

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

    func recurrenceDay(from dow: EKRecurrenceDayOfWeek) -> Int {
        let day: DayOfWeek = DayOfWeek(rawValue: dow.dayOfTheWeek.rawValue) ?? .sunday
        return day.toInt(week: dow.weekNumber)
    }


    func asSeries(for event: EKEvent, in calendar: EKCalendar) -> Series {
        let data: ModelInitData = ["id": event.cleanId,
                                   "title": event.title,
                                   "startTime": event.startDate.secondsSinceReferenceDate,
                                   "typeString": event.type.rawValue,
                                   "endTime": recurrenceEnd?.endDate?.secondsSinceReferenceDate ?? 0,
                                   "originString": event.getOrigin(in: calendar).rawValue,
                                   "template": event.asTemplate(in: calendar),
                                   "recurrence": self.asRecurrence(on: event.startDate)]
        return Series(value: data)
    }

    func asRecurrence(on date: Date) -> Recurrence {
        let recurrence = Recurrence(value: ["frequencyRaw": getFrequency().rawValue,
                                            "interval": interval,
                                            "weekStartRaw": weekStart().rawValue,
                                            "count": recurrenceEnd?.occurrenceCount ?? 0])

        if let weekdays = daysOfTheWeek {
            weekdays.forEach { recurrence.daysOfWeek.append(recurrenceDay(from: $0)) }

        } else if getFrequency() == .weekly {
            recurrence.daysOfWeek.append(DayOfWeek.from(date: date).toInt())
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
