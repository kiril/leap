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

    func weekStart() -> Weekday {
        switch firstDayOfTheWeek {
        case 0: // unset onthis rule, so default to Sunday
            return .sunday
        default:
            return Weekday.from(gregorian: firstDayOfTheWeek)
        }
    }

    func recurrenceDay(from dow: EKRecurrenceDayOfWeek) -> Int {
        return OrdinalWeekday(Weekday.from(gregorian: dow.dayOfTheWeek.rawValue), dow.weekNumber).encode()
    }

    func asSeries(for event: EKEvent, in calendar: EKCalendar) -> Series {
        let origin = event.getOrigin(in: calendar)
        let participants = event.getParticipants(origin: origin)
        let engagement = (participants.me?.engagement ?? .none)
        let data: ModelInitData = ["id": event.cleanId,
                                   "title": event.title,
                                   "startTime": event.startDate.secondsSinceReferenceDate,
                                   "typeString": event.type.rawValue,
                                   "endTime": recurrenceEnd?.endDate?.secondsSinceReferenceDate ?? 0,
                                   "originString": origin.rawValue,
                                   "template": event.asTemplate(in: calendar),
                                   "engagementString": engagement.rawValue,
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
            recurrence.daysOfWeek.append(Weekday.of(date).rawValue)
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

        if getFrequency() == .yearly && recurrence.daysOfYear.isEmpty && recurrence.weeksOfYear.isEmpty && recurrence.monthsOfYear.isEmpty && recurrence.setPositions.isEmpty {
            recurrence.monthsOfYear.append(Recurrence.calendar.component(.month, from: date))
            recurrence.daysOfMonth.append(Recurrence.calendar.component(.day, from: date))
        }
        
        return recurrence
    }
}
