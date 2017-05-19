//
//  DaySequence.swift
//  Leap
//
//  Created by Kiril Savino on 5/18/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class DaySequence: Sequence {
    let iterator: DayIterator

    init(_ iterator: DayIterator) {
        self.iterator = iterator
    }

    convenience init(traversal: DayTraversal, start: Date, max: Int = 0) {
        self.init(DayIterator(using: traversal, startingWith: start, max: max))
    }

    func makeIterator() -> DayIterator {
        iterator.reset()
        return iterator
    }

    static func month(of d: Date, using calendar: Calendar, reversed: Bool = false) -> DaySequence {
        let month = calendar.component(.month, from: d)
        let year = calendar.component(.year, from: d)
        let start = reversed ? calendar.endOfMonth(including: d) : calendar.startOfMonth(including: d)
        var traversal: DayTraversal = MonthBoundDayTraversal(using: calendar, in: month, of: year)
        if reversed {
            traversal = traversal.reversed()
        }
        return DaySequence(traversal: traversal, start: start)
    }

    static func year(of d: Date, using calendar: Calendar, reversed: Bool = false) -> DaySequence {
        let year = calendar.component(.year, from: d)
        let start = reversed ? calendar.endOfYear(including: d) : calendar.startOfYear(including: d)
        var traversal: DayTraversal = YearBoundDayTraversal(using: calendar, of: year)
        if reversed {
            traversal = traversal.reversed()
        }

        return DaySequence(traversal: traversal, start: start)
    }

    static func weekdays(startingAt start: Date, using calendar: Calendar, weekdays: [Int]? = nil, max: Int = 0, reversed: Bool = false) -> DaySequence {
        var traversal:DayTraversal = WeekdayTraversal(using: calendar, weekdays: weekdays)
        if reversed {
            traversal = traversal.reversed()
        }
        return DaySequence(traversal: traversal, start: start, max: max)
    }

    static func monthly(startingAt start: Date, using calendar: Calendar, on days: [Int], max: Int = 0, reversed: Bool = false) -> DaySequence {
        var traversal: DayTraversal = DayOfMonthTraversal(using: calendar, on: days)
        if reversed {
            traversal = traversal.reversed()
        }
        return DaySequence(traversal: traversal, start: start, max: max)
    }
}
