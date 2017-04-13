//
//  Recurrence.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum Frequency: String {
    case unknown = "unknown"
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    case yearly  = "yearly"
}

enum DayOfWeek: Int {
    case sunday    = 1
    case monday    = 2
    case tuesday   = 3
    case wednesday = 4
    case thursday  = 5
    case friday    = 6
    case saturday  = 7

    static func from(date: Date) -> DayOfWeek {
        let components = Calendar.current.dateComponents([Calendar.Component.weekday], from: date)
        return DayOfWeek(rawValue: components.weekday!)!
    }
}

class RecurrenceDay: Object {
    dynamic var id: Int = 0
    dynamic var dayOfWeekRaw: Int = DayOfWeek.sunday.rawValue
    dynamic var week: Int = 0 // 1-indexed

    var dayOfWeek: DayOfWeek {
        get { return DayOfWeek(rawValue: dayOfWeekRaw)! }
        set { dayOfWeekRaw = newValue.rawValue }
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    static func of(day: DayOfWeek, in week: Int = 0) -> RecurrenceDay {
        return RecurrenceDay(value: ["id": week*1000 + day.rawValue,
                                     "dayOfWeekRaw": day.rawValue,
                                     "week": week])
    }
}


// NOTE: can you indicate attendence to all future?
// Can you make it such that editing doesn't by default even touch the recurrence?
class Recurrence: LeapModel {
    dynamic var startHour: Int = 0
    dynamic var startMinute: Int = 0
    dynamic var durationMinutes: Int = 0
    dynamic var leadTime: Double = 0.0
    dynamic var trailTime: Double = 0.0
    dynamic var count: Int = 0
    dynamic var frequencyRaw: String = Frequency.unknown.rawValue
    dynamic var interval: Int = 0
    dynamic var referenceEvent: Event?
    dynamic var weekStartRaw: Int = DayOfWeek.sunday.rawValue

    let daysOfWeek = List<RecurrenceDay>()
    let daysOfMonth = List<IntWrapper>()
    let daysOfYear = List<IntWrapper>()
    let weeksOfYear = List<IntWrapper>()
    let monthsOfYear = List<IntWrapper>()
    let setPositions = List<IntWrapper>()

    var weekStart: DayOfWeek {
        get { return DayOfWeek(rawValue: weekStartRaw)! }
        set { weekStartRaw = newValue.rawValue }
    }

    var frequency: Frequency {
        get { return Frequency(rawValue: frequencyRaw)! }
        set { frequencyRaw = newValue.rawValue }
    }

    func recursOn(date: Date, for series: Series) -> Bool {
        // start with frequency, and then you know how to qualify to begin with, and what to test
        // use the interval to further narrow
        // look at all of the dates in the range to see if we're in a range we exist
        // count the # of recurrences according to the pattern
        // check the actual constraints (day of X, setPositions)

        let calendar = Calendar.current

        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let week = calendar.component(.weekOfYear, from: date)

        if daysOfMonth.count > 0, !daysOfMonth.contains(IntWrapper.of(day)) {
            return false
        }

        if daysOfYear.count > 0, !daysOfYear.contains(IntWrapper.of(calendar.ordinality(of: .day, in: .year, for: date)!)) {
            return false
        }

        if weeksOfYear.count > 0, !weeksOfYear.contains(IntWrapper.of(week)) {
            return false
        }

        if monthsOfYear.count > 0, !monthsOfYear.contains(IntWrapper.of(month)) {
            return false
        }

        switch frequency {
        case .daily:
            if interval != 0 {
                let daysSinceStart = calendar.daysBetween(series.startDate, and: date)
                if daysSinceStart % interval != 0 {
                    return false
                }
            }
            // TODO: recurrence count/end time?
            return true

        case .weekly:
            let weeksSinceStart = calendar.weeksBetween(series.startDate, and: date)
            if interval != 0 {
                if weeksSinceStart % interval != 0 {
                    return false
                }
            }
            // TODO: recurrence count/end time?
            return true

        case .monthly:
            let monthsSinceStart = calendar.monthsBetween(series.startDate, and: date)
            if interval != 0 {
                if monthsSinceStart % interval != 0 {
                    return false
                }
            }

            if daysOfWeek.count > 0 {
                let weekInMonth = calendar.ordinality(of: .weekOfMonth, in: .month, for: date)!
                let weekdayInWeek = RecurrenceDay.of(day: DayOfWeek.from(date: date), in: weekInMonth)
                let anyWeekday = RecurrenceDay.of(day: DayOfWeek.from(date: date))
                if !daysOfWeek.contains(weekdayInWeek), !daysOfWeek.contains(anyWeekday) {
                    return false
                }

                if setPositions.count > 0 {
                }
            }
            // TODO: recurrence count/end time?
            return true

        case .yearly:
            let yearsSinceStart = calendar.yearsBetween(series.startDate, and: date)
            if interval != 0 {
                if yearsSinceStart % interval != 0 {
                    return false
                }
            }

            if monthsOfYear.count > 0, !monthsOfYear.contains(IntWrapper.of(month)) {
                return false
            }

            if weeksOfYear.count > 0, !weeksOfYear.contains(IntWrapper.of(week)) {
                return false
            }

            if daysOfYear.count > 0, !daysOfYear.contains(IntWrapper.of(calendar.ordinality(of: .day, in: .year, for: date)!)) {
                return false
            }

            return true

        case .unknown:
            return false
        }
    }
}
