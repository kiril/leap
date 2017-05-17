//
//  Calendar+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

import EventKit

let GregorianSunday = 1
let GregorianMonday = 2
let GregorianTuesday = 3
let GregorianWednesday = 4
let GregorianThursday = 5
let GregorianFriday = 6
let GregorianSaturday = 7

let GregorianWeekdays = [GregorianMonday, GregorianTuesday, GregorianWednesday, GregorianThursday, GregorianFriday]
let GregorianWeekends = [GregorianSunday, GregorianSaturday]

extension Int {
    var weekdayString: String {
        switch self {
        case GregorianSunday:
            return "Sunday"
        case GregorianMonday:
            return "Monday"
        case GregorianTuesday:
            return "Tuesday"
        case GregorianWednesday:
            return "Wednesday"
        case GregorianThursday:
            return "Thursday"
        case GregorianFriday:
            return "Friday"
        case GregorianSaturday:
            return "Saturday"
        default:
            fatalError()
        }
    }
}

extension EKWeekday {
    static func from(gregorian: Int) -> EKWeekday {
        switch gregorian {
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
            fatalError()
        }
    }

    var gregorianWeekday: Int {
        return self.rawValue
    }

    var stringValue: String {
        switch self {
        case .sunday:
            return "Sunday"
        case .monday:
            return "Monday"
        case .tuesday:
            return "Tuesday"
        case .wednesday:
            return "Wednesday"
        case .thursday:
            return "Thursday"
        case .friday:
            return "Friday"
        case .saturday:
            return "Saturday"
        }
    }
}

typealias DateTest = (Date) -> Bool

class DayIterator: IteratorProtocol {
    let calendar: Calendar
    let test: DateTest
    let start: Date
    let reversed: Bool
    var date: Date

    init(calendar: Calendar, start: Date, while test: @escaping DateTest, reversed: Bool) {
        self.calendar = calendar
        self.start = start
        self.date = start
        self.test = test
        self.reversed = reversed
    }

    func next() -> Date? {
        let ret = date
        if !test(ret) {
            return nil
        }

        self.date = reversed ? calendar.dayBefore(self.date) : calendar.dayAfter(self.date)
        return ret
    }

    func reset() {
        date = start
    }
}

class DaySequence: Sequence {
    let iterator: DayIterator
    init(_ iterator: DayIterator) {
        self.iterator = iterator
    }

    func makeIterator() -> DayIterator {
        iterator.reset()
        return iterator
    }
}

extension Calendar {

    func formatDisplayTime(from date: Date, needsAMPM: Bool) -> String {
        // maybe this can be done with a DateFormatter, but for now I'm
        // just going to code it up manually
        let hour = component(Calendar.Component.hour, from: date)
        let minute = component(Calendar.Component.minute, from: date)

        let nonMilitaryHour = hour == 12 ? 12 : hour % 12

        let hourString = String(format: "%d", nonMilitaryHour)
        let minuteString = minute > 0 ? String(format: ":%02d", minute) : ""
        let ampmString = needsAMPM ? (hour < 12 ? "am" : "pm") : ""
        return hourString + minuteString + ampmString
    }

    func areOnDifferentDays(_ a: Date, _ b: Date) -> Bool {
        let ay = component(.year, from: a)
        let am = component(.month, from: a)
        let ad = component(.day, from: a)

        let by = component(.year, from: b)
        let bm = component(.month, from: b)
        let bd = component(.day, from: b)

        return ay != by || am != bm || ad != bd
    }

    func daysBetween(_ a: Date, and b: Date) -> Int {
        let aYear = component(.year, from: a)
        let aDayOfYear = ordinality(of: .day, in: .year, for: a)!

        let bYear = component(.year, from: b)
        let bDayOfYear = ordinality(of: .day, in: .year, for: b)!

        var interveningDays = 0
        var year = min(aYear, bYear)
        let endYear = max(aYear, bYear)
        while year < endYear {
            let lastDay = date(from: DateComponents(year: year, month: 12, day: 31))!
            let daysInYear = ordinality(of: .day, in: .year, for: lastDay)!
            interveningDays += daysInYear
            year += 1
        }

        if bYear < aYear {
            interveningDays *= -1
        }

        return interveningDays + (bDayOfYear - aDayOfYear)
    }

    func weeksBetween(_ a: Date, and b: Date) -> Int {
        let days = daysBetween(a, and: b)
        var weeks = days % 7
        if weeks * 7 < days {
            weeks += 1
        }
        return weeks
    }

    func monthsBetween(_ a: Date, and b: Date) -> Int {
        let aYear = component(.year, from: a)
        let aMonthOfYear = ordinality(of: .month, in: .year, for: a)!

        let bYear = component(.year, from: b)
        let bMonthOfYear = ordinality(of: .month, in: .year, for: b)!

        return (bYear - aYear) * 12 + (bMonthOfYear - aMonthOfYear)
    }

    func yearsBetween(_ a: Date, and b: Date) -> Int {
        return component(.year, from: b) - component(.year, from: a)
    }

    func todayAt(hour: Int, minute: Int) -> Date {
        return self.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
    }

    func todayAtRandom(after: Date? = nil) -> Date {
        var components: DateComponents!
        if let after = after {
            let atLeastHour = self.component(Calendar.Component.hour, from: after)
            components = DateComponents(hour: atLeastHour+Int.random(24-atLeastHour-1)+1, minute: Int.random(60))
        } else {
            components = DateComponents(hour: Int.random(24), minute: Int.random(60))
        }
        return self.date(from: components)!
    }

    func isDate(_ a: Date, before b: Date) -> Bool {
        switch compare(a, to: b, toGranularity: .minute) {
        case .orderedAscending:
            return true
        default:
            return false
        }
    }

    func isDate(_ a: Date, after b: Date) -> Bool {
        switch compare(a, to: b, toGranularity: .minute) {
        case .orderedDescending:
            return true
        default:
            return false
        }
    }

    func dayAfter(_ d: Date) -> Date {
        return date(byAdding: .day, value: 1, to: d)!
    }

    func dayBefore(_ d: Date) -> Date {
        return date(byAdding: .day, value: -1, to: d)!
    }

    func adding(days: Int, to d: Date) -> Date {
        return date(byAdding: .day, value: days, to: d)!
    }

    func subtracting(days: Int, from d: Date) -> Date {
        return date(byAdding: .day, value: -days, to: d)!
    }

    func theNext(weekday desired: Int, onOrAfter d: Date) -> Date {
        let weekday = component(.weekday, from: d)
        if weekday == desired {
            return d
        }
        if desired > weekday {
            return adding(days: (desired-weekday), to: d)
        }
        let delta = 7 - (weekday - desired)
        return adding(days: delta, to: d)
    }

    func theNext(weekday: Int, after d: Date) -> Date {
        return theNext(weekday: weekday, onOrAfter: dayAfter(d))
    }

    func theNext(_ weekday: Weekday, after d: Date) -> Date {
        return theNext(weekday: weekday.gregorianIndex, after: d)
    }

    func theNext(_ weekday: Weekday, onOrAfter d: Date) -> Date {
        return theNext(weekday: weekday.gregorianIndex, onOrAfter: d)
    }

    func theLast(_ weekday: Weekday, before d: Date) -> Date {
        return theLast(weekday: weekday.gregorianIndex, before: d)
    }

    func theLast(weekday desired: Int, before d: Date) -> Date {
        return theLast(weekday: desired, onOrBefore: dayBefore(d))
    }

    func theLast(_ weekday: Weekday, onOrBefore d: Date) -> Date {
        return theLast(weekday: weekday.gregorianIndex, onOrBefore: d)
    }

    func theLast(weekday desired: Int, onOrBefore d: Date) -> Date {
        let weekday = component(.weekday, from: d)
        let delta:Int = weekday - desired

        switch delta {
        case 1...Int.max:
            return subtracting(days: delta, from: d)

        case Int.min..<0:
            let daysInFuture = -delta // verbose because...
            let daysIntoPast = 7 - daysInFuture // ... then this logic is more transparent
            return subtracting(days: daysIntoPast, from: d)

        case 0:
            return d

        default:
            fatalError()
        }
    }

    func startOfMonth(onOrAfter d: Date) -> Date {
        return date(bySetting: .day, value: 1, of: d)!
    }

    func startOfYear(onOrAfter d: Date) -> Date {
        return date(bySetting: .month, value: 1, of: date(bySetting: .day, value: 1, of: d)!)!
    }

    func startOfMonth(including d: Date) -> Date {
        let daysBackToFirst = component(.day, from: d) - 1
        return date(byAdding: .day, value: -daysBackToFirst, to: d)!
    }

    func startOfYear(including d: Date) -> Date {
        let first = startOfMonth(including: d)
        return date(byAdding: .month, value: -(component(.month, from: first)-1), to: first)!
    }

    func all(weekdays day: Int, inMonthOf date: Date) -> [Date] {
        let theFirst = startOfMonth(including: date)

        let month = component(.month, from: theFirst)
        var one = theNext(weekday: day, onOrAfter: theFirst)
        var weekdays: [Date] = []
        while component(.month, from: one) == month {
            weekdays.append(one)
            one = theNext(weekday: day, after: one)
        }
        return weekdays
    }

    func sequence(from start: Date, while test: @escaping DateTest) -> DaySequence {
        return sequence(from: start, while: test, reversed: false)
    }

    func sequence(from start: Date, while test: @escaping DateTest, reversed: Bool) -> DaySequence {
        return DaySequence(DayIterator(calendar: self, start: start, while: test, reversed: reversed))
    }

    func allDays(inMonthOf d: Date) -> DaySequence {
        let theFirst = startOfMonth(including: d)
        let month = self.component(.month, from: theFirst)
        return sequence(from: theFirst, while: {day in return self.component(.month, from: day) == month })
    }

    func allDays(inYearOf d: Date) -> DaySequence {
        let theFirst = startOfYear(including: d)
        let year = self.component(.year, from: theFirst)
        return sequence(from: theFirst, while: {day in return self.component(.year, from: day) == year })
    }

    func allDaysReversed(inYearOf d: Date) -> DaySequence {
        let lastDay = dayBefore(date(byAdding: .year, value: 1, to: startOfYear(including: d))!)
        let year = self.component(.year, from: lastDay)
        return sequence(from: lastDay, while: {day in return self.component(.year, from: day) == year }, reversed: true)
    }

    func all(weekdays day: Int, inYearOf date: Date) -> [Date] {
        let theFirst = startOfYear(including: date)

        let year = component(.year, from: theFirst)
        var one = theNext(weekday: day, onOrAfter: theFirst)
        var weekdays: [Date] = []
        while component(.year, from: one) == year {
            weekdays.append(one)
            one = theNext(weekday: day, after: one)
        }
        return weekdays
    }

    func isDate(_ date: Date, a weekday: Int) -> Bool {
        return component(.weekday, from: date) == weekday
    }

    func isWeekday(_ date: Date) -> Bool {
        switch component(.weekday, from: date) {
        case GregorianSunday, GregorianSaturday:
            return false
        default:
            return true
        }
    }

    func isWeekend(_ date: Date) -> Bool {
        switch component(.weekday, from: date) {
        case GregorianSunday, GregorianSaturday:
            return true
        default:
            return false
        }
    }

    func isDate(_ a: Date, theSameDayAs b: Date) -> Bool {
        if a == b {
            return true
        }
        if component(.year, from: a) != component(.year, from: b) {
            return false
        }
        if component(.month, from: a) != component(.month, from: b) {
            return false
        }
        if component(.day, from: a) != component(.day, from: b) {
            return false
        }
        return true
    }

    func isDate(_ d: Date, between start: Date, and end: Date) -> Bool {
        return isDate(d, after: start) && isDate(d, before: end)
    }

    func isDate(_ d: Date, betweenInclusive start: Date, and end: Date) -> Bool {
        return !isDate(d, before: start) && isDate(d, before: end)
    }

    func weekdayOrdinal(of date: Date) -> Int {
        let month = self.component(.month, from: date)
        let weekday = self.component(.weekday, from: date)
        let firstOfMonth = self.startOfMonth(including: date)
        let firstWeekday = self.theNext(weekday: weekday, onOrAfter: firstOfMonth)
        var d = firstWeekday
        var nth = 0
        while self.component(.month, from: d) == month {
            nth += 1
            if self.isDate(d, inSameDayAs: date) {
                break
            }
            d = self.theNext(weekday: weekday, after: d)
        }
        return nth
    }

    func count(weekday: Int, inMonthOf date: Date) -> Int {
        let firstOfMonth = self.startOfMonth(including: date)
        let firstWeekday = self.theNext(weekday: weekday, onOrAfter: firstOfMonth)
        let dayOfFirstWeekday = self.component(.day, from: firstWeekday)
        let daysInMonth = self.range(of: .day, in: .month, for: date)!.upperBound - 1
        let daysRemaining = daysInMonth - dayOfFirstWeekday
        let weeksRemaining = daysRemaining / 7
        return weeksRemaining + 1
    }

    func negativeOrdinal(ordinal: Int, total: Int) -> Int {
        return (ordinal - total) - 1
    }

    func daysInYear(including date: Date) -> Int {
        let daysInFebruary = self.range(of: .day, in: .month, for: self.date(bySetting: .month, value: 2, of: date)!)!.upperBound - 1
        return 365 + (daysInFebruary - 28)
    }

    func shortDateString(from day: GregorianDay) -> String {
        let d = date(from: day.components)!
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: d)
    }

    func shortDateString(from d: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: d)
    }
}
