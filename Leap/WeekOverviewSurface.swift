//
//  WeekOverviewViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol IntIdInitable {
    init(intId: Int)
    var intId: Int { get }
}

class WeekOverviewSurface: Surface, IntIdInitable {
    var delegate: ViewModelDelegate?
    let daysInAWeek = 7

    convenience required init(intId: Int) {
        self.init(id: String(intId))
    }
    var intId: Int { return Int(id!)! }

    // The id of a week points to the id of the first day of the week (which might be a Sunday or Monday, depending
    // on the preferences of the observing user. But this id is transient so that's okay

    convenience init(containingDayId dayId: String) {
        let targetDay = DaySurface(id: dayId)

        let beginningOfWeekId = targetDay.intId - targetDay.weekdayIndex

        self.init(intId: beginningOfWeekId)
    }

    var weekAfter: WeekOverviewSurface {
        return WeekOverviewSurface(intId: intId + daysInAWeek)
    }

    var weekBefore: WeekOverviewSurface {
        return WeekOverviewSurface(intId: intId - daysInAWeek)
    }

    var titleForWeek: String {
        let firstDay = days.first!
        let lastDay = days.last!

        let firstDayString = "\(firstDay.monthNameShort) \(firstDay.dayOfTheMonth)"
        let lastDayString = "\(lastDay.monthNameShort) \(lastDay.dayOfTheMonth), \(lastDay.year)"
        return "\(firstDayString) - \(lastDayString)"
    }

    var days: [DaySurface] {
        var days = [DaySurface]()

        for i in 0...(daysInAWeek - 1) {
            days.append(DaySurface(id: String(intId + i)))
        }

        return days
    }
}

class DaySurface: Surface, IntIdInitable {
    // how is this different from a day schedule view model? Does the day schedule view model end up using this to display things like the day name, etc.?

    convenience required init(intId: Int) {
        self.init(id: String(intId))
    }
    var intId: Int { return Int(id!)! }
    private var gregorianDay: GregorianDay { return GregorianDay(id: intId) }

    var weekdayName: String {
        return Calendar.current.weekdaySymbols[weekdayIndex] // force gregorian here but change the locale? Maybe... maybe.
    }

    var weekdayNameShort: String {
        return Calendar.current.shortWeekdaySymbols[weekdayIndex] // force gregorian here but change the locale? Maybe... maybe.
    }

    private var weekdayInt: Int { // Sunday is 1 by default, index 1
        return Calendar.current.dayOfTheWeek(for: gregorianDay)
    }

    var weekdayIndex: Int { // Sunday is 0 by default, index 0
        return weekdayInt - 1
    }

    private var monthIndex: Int {
        return gregorianDay.month - 1
    }

    var monthNameShort: String {
        return Calendar.current.shortMonthSymbols[monthIndex]
    }

    var monthName: String {
        return Calendar.current.monthSymbols[monthIndex]
    }

    var year: String {
        return String(gregorianDay.year)
    }

    var dayOfTheMonth: String {
        return String(gregorianDay.day)
    }

    var overviewDescription: String {
        return "\(dayOfTheMonth) \(weekdayName)"
    }

    var happensIn: TimePerspective {
        let today = Calendar.current.today

        if intId > today.id {
            return .future
        }
        else if intId < today.id {
            return .past
        }
        else {
            return .current
        }
    }

    var isToday: Bool {
        return happensIn == .current
    }
}
