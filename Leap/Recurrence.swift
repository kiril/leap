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

    func toInt(week: Int = 0) -> Int {
        if week == 0 {
            return self.rawValue
        }
        return week > 0 ? (week * 1000) + self.rawValue : (week * 1000) - self.rawValue
    }

    static func from(int: Int) -> DayOfWeek {
        switch abs(int) % 1000 {
        case 1:
            return .sunday
        case 2:
            return .monday
        case 3:
            return .tuesday
        case 4:
            return .wednesday
        case 5:
            return .thursday
        case 6:
            return .friday
        case 7:
            return .saturday
        default:
            fatalError("Invalid day of week \(int)")
        }
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

    let daysOfWeek = List<IntWrapper>()
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

    func coRecurs(with other: Recurrence) -> Bool {
        guard frequency == other.frequency else { return false }
        guard interval == other.interval else { return false }
        guard daysOfWeek.hasEqualContents(to: other.daysOfWeek) else { return false }
        guard daysOfMonth.hasEqualContents(to: other.daysOfMonth) else { return false }
        guard weeksOfYear.hasEqualContents(to: other.weeksOfYear) else { return false }
        guard monthsOfYear.hasEqualContents(to: other.monthsOfYear) else { return false }
        guard setPositions.hasEqualContents(to: other.setPositions) else { return false }

        return true // well, ok then! :)
    }

    public static func every(_ frequency: Frequency, max count: Int = 0, by interval: Int = 0, on weekday: Weekday? = nil, the day: Int? = nil) -> Recurrence {
        var data: ModelInitData = ["frequencyRaw": frequency.rawValue,
                                   "count": count,
                                   "interval": interval]
        if let weekday = weekday {
            data["daysOfWeek"] = List<IntWrapper>([IntWrapper.of(weekday.gregorianIndex)])

        } else if let day = day {
            data["daysOfMonth"] = List<IntWrapper>([IntWrapper.of(day)])
        }
        return Recurrence(value: data)
    }

    func dayOfWeekMatches(for date: Date) -> Bool {
        guard daysOfWeek.count > 0 else { return true }
        let day = DayOfWeek.from(date: date)

        if daysOfWeek.contains(day.toInt()) { // 'any Tuesday' is in there, so yay
            return true
        }

        // now calculate the exact nth Tuesday, both as a positive and a negative
        let ordinal = Recurrence.calendar.weekdayOrdinal(of: date)
        let totalWeekdays = Recurrence.calendar.count(weekday: day.rawValue, inMonthOf: date)

        if daysOfWeek.contains(day.toInt(week: ordinal)) { // exact positive-index match
            return true
        }

        let negativeOrdinal = Recurrence.calendar.negativeOrdinal(ordinal: ordinal, total: totalWeekdays)

        if daysOfWeek.contains(day.toInt(week: negativeOrdinal)) { // exact positive-index match
            return true
        }

        return false
    }

    func recurs(on date: Date, for series: Series) -> Bool {
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
            print("wrong day of week")
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
                print("interval = \(interval), weeks = \(weeksSinceStart) given \(series.startDate) and \(date)8")
                if weeksSinceStart % interval != 0 {
                    print("fail: \(weeksSinceStart) % \(interval) = \(weeksSinceStart % interval), not 0")
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
                let daysInYear = calendar.daysInYear(including: date)
                let weekdays = daysOfWeek.map({ $0.raw }).sorted()

                var positivePositions = setPositions.map({ $0.raw }).filter({ $0 >= 0 }).sorted()
                let negativePositions = setPositions.map({ $0.raw }).filter({ $0 < 0 }).sorted()

                let start = calendar.startOfYear(including: date)
                let startWeekday = calendar.component(.weekday, from: start)

                let firstWeekday = weekdays.filter({ $0 >= startWeekday }).first ?? weekdays.first!
                let firstMatch = calendar.theNext(weekday: firstWeekday, onOrAfter: start)

                let matchesPerWeek = weekdays.count
                let dayOfYearForFirstMatch = calendar.component(.day, from: firstMatch) // valid because January! :)
                let fullWeeksRemaining = (daysInYear - dayOfYearForFirstMatch) / 7
                let dayInYearOfLastFullWeek = dayOfYearForFirstMatch + (fullWeeksRemaining * 7)
                let daysRemainingInYear = daysInYear - dayInYearOfLastFullWeek

                var matchesInTrailingWeek = 0
                for weekday in weekdays {
                    let daysTilNext = (weekday > firstWeekday) ? weekday - firstWeekday : 7 - (firstWeekday - weekday)
                    if daysTilNext <= daysRemainingInYear {
                        matchesInTrailingWeek += 1
                    }
                }
                let totalMatchesInYear = 1 + (fullWeeksRemaining * matchesPerWeek) + matchesInTrailingWeek
                negativePositions.forEach {
                    let positiveTranslation = totalMatchesInYear + $0 + 1 // 1-indexed
                    if !positivePositions.contains(positiveTranslation) { positivePositions.append(positiveTranslation) }
                }
                positivePositions.sort()

                for position in positivePositions {
                    if position == 1 {
                        if calendar.isDate(date, inSameDayAs: firstMatch) {
                            return true
                        }
                    } else {
                        let deltaToPosition = position - 1
                        let weekOffset = deltaToPosition / matchesPerWeek
                        let matchOffset = deltaToPosition % matchesPerWeek
                        var d = calendar.date(byAdding: .day, value: weekOffset * 7, to: firstMatch)!
                        if matchOffset == 0 {
                            return weekdays.contains(calendar.component(.weekday, from: d)) && calendar.isDate(date, inSameDayAs: d)
                        }

                        var matches = 0
                        repeat {
                            d = calendar.dayAfter(d)
                            if d > date {
                                return false
                            }
                            if weekdays.contains(calendar.component(.weekday, from: d)) {
                                matches += 1
                                if matches == matchOffset && calendar.isDate(date, inSameDayAs: d) {
                                    return true
                                }
                            }
                        } while matches < matchOffset
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
