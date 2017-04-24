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


public enum DayOfWeek: Int {
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

    private static var _recurrenceDayCache: [Int:[Int:RecurrenceDay]] = [:]

    var dayOfWeek: DayOfWeek {
        get { return DayOfWeek(rawValue: dayOfWeekRaw)! }
        set { dayOfWeekRaw = newValue.rawValue }
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    static func of(day: DayOfWeek, in week: Int = 0) -> RecurrenceDay {
        let dayId = week * 1000 + day.rawValue
        let realm = Realm.user()

        if let d = realm.objects(RecurrenceDay.self).filter("id = %d", dayId).first {
            return d
        }

        let rd = RecurrenceDay(value: ["id": dayId,
                                       "dayOfWeekRaw": day.rawValue,
                                       "week": week])
        try! realm.safeWrite {
            realm.add(rd)
        }
        return rd
    }

    override var hashValue: Int {
        return id
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let rd = object as? RecurrenceDay {
            return rd.id == self.id
        }
        return false
    }

    static func == (lhs: RecurrenceDay, rhs: RecurrenceDay) -> Bool {
        return lhs.id == rhs.id
    }
}


// NOTE: can you indicate attendence to all future?
// Can you make it such that editing doesn't by default even touch the recurrence?
class Recurrence: LeapModel {
    static let calendar = Calendar(identifier: .gregorian)

    dynamic var count: Int = 0
    dynamic var frequencyRaw: String = Frequency.unknown.rawValue
    dynamic var interval: Int = 0
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

    public static func every(_ frequency: Frequency, at minute: Int = 0, past hour: Int = 0, max count: Int = 0, interval: Int = 0, on dayOfMonth: Int = 0) -> Recurrence {
        let data: ModelInitData = ["startHour": hour,
                                   "startMinute": minute,
                                   "frequencyRaw": frequency.rawValue,
                                   "count": count,
                                   "interval": interval]
        return Recurrence(value: data)
    }

    func dayOfWeekMatches(for date: Date) -> Bool {
        guard daysOfWeek.count > 0 else { return true }
        let week = Recurrence.calendar.ordinality(of: .weekOfMonth, in: .month, for: date)!

        return daysOfWeek.contains(day: DayOfWeek.from(date: date), week: week) || daysOfWeek.contains(day: DayOfWeek.from(date: date), week: 0)
    }

    func recursOn(_ date: Date, for series: Series) -> Bool {
        // start with frequency, and then you know how to qualify to begin with, and what to test
        // use the interval to further narrow
        // look at all of the dates in the range to see if we're in a range we exist
        // count the # of recurrences according to the pattern
        // check the actual constraints (day of X, setPositions)

        let calendar = Calendar.current

        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let week = calendar.component(.weekOfYear, from: date)

        if !dayOfWeekMatches(for: date) {
            return false
        }

        if daysOfMonth.count > 0, !daysOfMonth.contains(day) {
            return false
        }

        if daysOfYear.count > 0, !daysOfYear.contains(calendar.ordinality(of: .day, in: .year, for: date)!) {
            return false
        }

        if weeksOfYear.count > 0, !weeksOfYear.contains(week) {
            return false
        }

        if monthsOfYear.count > 0, !monthsOfYear.contains(month) {
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
            return true

        case .weekly:
            let weeksSinceStart = calendar.weeksBetween(series.startDate, and: date)
            if interval != 0 {
                if weeksSinceStart % interval != 0 {
                    return false
                }
            }
            return true

        case .monthly:
            let monthsSinceStart = calendar.monthsBetween(series.startDate, and: date)
            if interval != 0 {
                if monthsSinceStart % interval != 0 {
                    return false
                }
            }

            if setPositions.count > 0 && daysOfWeek.count > 0 {
                // we know that we match one of these days...
                // but now we have to see if we're one of the 'nth' ones for a given position
                // so...
                // let's figure out what index this date is within this month
                // that requires counting all the matching weekdays in this month until we find this date
                var matchIndices: [Int] = []
                var myIndex = -1
                var i = 0
                for day in calendar.allDays(inMonthOf: date) {
                    if dayOfWeekMatches(for: day) {
                        matchIndices.append(i)
                        if calendar.isDate(day, theSameDayAs: date) {
                            myIndex = i
                            if setPositions.contains(matchIndices.count) {
                                return true // may as well succeed fast in the simple case
                            }
                        }
                    }
                    i += 1
                }

                for position in setPositions.map({ return $0.raw }) {
                    let positionalIndex = position < 0 ? matchIndices[matchIndices.count+position] : matchIndices[position-1]
                    if abs(position) < matchIndices.count && positionalIndex == myIndex {
                        return true
                    }
                }
                return false
            }
            return true

        case .yearly:
            let yearsSinceStart = calendar.yearsBetween(series.startDate, and: date)
            if interval != 0 {
                if yearsSinceStart % interval != 0 {
                    return false
                }
            }

            if monthsOfYear.count > 0, !monthsOfYear.contains(month) {
                return false
            }

            if weeksOfYear.count > 0, !weeksOfYear.contains(week) {
                return false
            }

            if daysOfYear.count > 0, !daysOfYear.contains(calendar.ordinality(of: .day, in: .year, for: date)!) {
                return false
            }

            if setPositions.count > 0 && daysOfWeek.count > 0 {
                // we know that we match one of these days...
                // but now we have to see if we're one of the 'nth' ones for a given position
                // so...
                // let's figure out what index this date is within this month
                // that requires counting all the matching weekdays in this month until we find this date
                let positions = setPositions.map { return $0.raw }
                var haveNegative = false
                for position in positions {
                    if position < 0 {
                        haveNegative = true
                        break
                    }
                }
                var matchIndices: [Int] = []
                var myPosition = -1

                let allYear = calendar.allDays(inYearOf: date)

                var i = 0
                for aDay in allYear {
                    if dayOfWeekMatches(for: aDay) {
                        matchIndices.append(i)
                        if calendar.isDate(aDay, theSameDayAs: date) {
                            myPosition = matchIndices.count
                            if positions.contains(myPosition) {
                                return true
                            }
                        }
                    } else if !haveNegative && myPosition != -1 {
                        return false
                    }
                    i += 1
                }

                for position in positions {
                    if position < 0 {
                        let adjusted = matchIndices.count + position + 1
                        if adjusted == myPosition {
                            return true
                        }
                    }
                }

                return false
            }

            return true

        case .unknown:
            return false
        }
    }
}
