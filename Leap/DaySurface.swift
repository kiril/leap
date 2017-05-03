//
//  DaySurface.swift
//  Leap
//
//  Created by Kiril Savino on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class DaySurface: Surface, IntIdInitable {
    // how is this different from a day schedule view model? Does the day schedule view model end up using this to display things like the day name, etc.?

    convenience required init(intId: Int) {
        self.init(id: String(intId))
    }
    var intId: Int { return Int(id!)! }
    var gregorianDay: GregorianDay { return GregorianDay.by(id: intId) }


    var shortDateString: String {
        let date = Calendar.current.date(from: gregorianDay.components)!
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

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

    var dayAfter: DaySurface {
        return DaySurface(intId: intId + 1)
    }

    var dayBefore: DaySurface {
        return DaySurface(intId: intId - 1)
    }
}
