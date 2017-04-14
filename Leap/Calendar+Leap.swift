//
//  Calendar+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

let GregorianSunday = 1
let GregorianMonday = 2
let GregorianTuesday = 3
let GregorianWednesday = 4
let GregorianThursday = 5
let GregorianFriday = 6
let GregorianSaturday = 7

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
            let lastDay = Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31))!
            let daysInYear = Calendar.current.ordinality(of: .day, in: .year, for: lastDay)!
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
        return date(byAdding: DateComponents(day: 1), to: d)!
    }

    func theNext(weekday: Int, onOrAfter date: Date) -> Date {
        var d = date
        while component(.weekday, from: d) != weekday {
            d = dayAfter(d)
        }
        return d
    }

    func theNext(weekday: Int, after date: Date) -> Date {
        return theNext(weekday: weekday, onOrAfter: dayAfter(date))
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

    func allDays(inMonthOf d: Date) -> [Date] {
        let theFirst = startOfMonth(including: d)
        var days: [Date] = []
        var day = theFirst
        while component(.month, from: day) == component(.month, from: theFirst) {
            days.append(day)
            day = dayAfter(day)
        }
        return days
    }

    func allDays(inYearOf d: Date) -> [Date] {
        let theFirst = startOfYear(including: d)
        var days: [Date] = []
        var day = theFirst
        while component(.year, from: day) == component(.year, from: theFirst) {
            days.append(day)
            day = dayAfter(day)
        }
        return days
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
}
