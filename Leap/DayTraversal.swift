//
//  DayTraversal.swift
//  Leap
//
//  Created by Kiril Savino on 5/18/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

protocol DayTraversal {
    func day(after: Date) -> Date?
    func day(before: Date) -> Date?
    func reversed() -> DayTraversal
}

extension DayTraversal {
    func reversed() -> DayTraversal {
        return ReverseDayTraversal(self)
    }
}


class ReverseDayTraversal: DayTraversal {
    private let traversal: DayTraversal

    init(_ traversal: DayTraversal) {
        self.traversal = traversal
    }

    func day(after d: Date) -> Date? {
        return traversal.day(before: d)
    }

    func day(before d: Date) -> Date? {
        return traversal.day(after: d)
    }
}


class CalendarDayTraversal: DayTraversal {
    private let calendar: Calendar

    init(_ calendar: Calendar) {
        self.calendar = calendar
    }

    func day(after d: Date) -> Date? {
        return calendar.dayAfter(d)
    }

    func day(before d: Date) -> Date? {
        return calendar.dayBefore(d)
    }
}


class MonthBoundDayTraversal: DayTraversal {
    private let calendar: Calendar
    private let month: Int
    private let year: Int
    private let traversal: DayTraversal

    init(using calendar: Calendar, in month: Int, of year: Int, traversal: DayTraversal? = nil) {
        self.calendar = calendar
        self.month = month
        self.year = year
        self.traversal = traversal ?? CalendarDayTraversal(calendar)
    }

    func day(after d: Date) -> Date? {
        if let next = traversal.day(after: d),
            calendar.component(.month, from: next) == month && calendar.component(.year, from: next) == year {
            return next
        }
        return nil
    }

    func day(before d: Date) -> Date? {
        if let prior = traversal.day(before: d),
            calendar.component(.month, from: prior) == month && calendar.component(.year, from: prior) == year {
            return prior
        }
        return nil
    }
}

class YearBoundDayTraversal: DayTraversal {
    private let calendar: Calendar
    private let year: Int
    private let traversal: DayTraversal

    init(using calendar: Calendar, of year: Int, traversal: DayTraversal? = nil) {
        self.calendar = calendar
        self.year = year
        self.traversal = traversal ?? CalendarDayTraversal(calendar)
    }

    func day(after d: Date) -> Date? {
        if let next = traversal.day(after: d),
            calendar.component(.year, from: next) == year {
            return next
        }
        return nil
    }

    func day(before d: Date) -> Date? {
        if let prior = traversal.day(before: d),
            calendar.component(.year, from: prior) == year {
            return prior
        }
        return nil
    }
}


class WeekdayTraversal: DayTraversal {
    private let calendar: Calendar
    private let weekdays: [Int]

    init(using calendar: Calendar, weekdays: [Int]? = nil) {
        if let weekdays = weekdays {
            self.weekdays = weekdays.sorted()
        } else {
            self.weekdays = [GregorianMonday, GregorianTuesday, GregorianWednesday, GregorianThursday, GregorianFriday]
        }
        self.calendar = calendar
    }

    func day(after d: Date) -> Date? {
        let weekday = calendar.component(.weekday, from: d)

        let next = (weekdays.first(where: {$0 > weekday}) ?? weekdays.first)!

        let daysAhead = (next == weekday ? 7 : (next < weekday ? 7-(weekday-next) : next-weekday))

        return calendar.adding(days: daysAhead, to: d)
    }

    func day(before d: Date) -> Date? {
        let weekday = calendar.component(.weekday, from: d)
        let prior = (weekdays.reversed().first(where: {$0 < weekday}) ?? weekdays.last)!

        let daysBack = (prior == weekday ? 7 : (prior < weekday ? weekday-prior : 7-(prior-weekday)))

        return calendar.subtracting(days: daysBack, from: d)
    }
}


class DayOfMonthTraversal: DayTraversal {
    private let calendar: Calendar
    private let days: [Int]

    init(using calendar: Calendar, on days: [Int]) {
        self.calendar = calendar
        self.days = days.sorted()
    }

    func day(after d: Date) -> Date? {
        let day = calendar.component(.day, from: d)

        if let after = days.filter({$0 > day}).first,
            let candidate = calendar.date(bySetting: .day, value: after, of: d),
            calendar.component(.month, from: candidate) == calendar.component(.month, from: d) {
            return candidate
        }

        return calendar.date(bySetting: .day, value: days.first!, of: d)
    }

    func day(before d: Date) -> Date? {
        let day = calendar.component(.day, from: d)

        if let before = days.filter({$0 < day}).last {
            let components = DateComponents(calendar: calendar, day: before)
            if let candidate = calendar.nextDate(after: d, matching: components, matchingPolicy: .nextTime, repeatedTimePolicy: .last, direction: .backward),
                calendar.component(.month, from: candidate) == calendar.component(.month, from: d) {
                return candidate
            }
        }

        let components = DateComponents(calendar: calendar, day: days.last!)
        return calendar.nextDate(after: d, matching: components, matchingPolicy: .nextTime, repeatedTimePolicy: .last, direction: .backward)
    }
}

