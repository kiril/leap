//
//  WeekOverviewViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import UIKit

class WeekOverviewSurface: Surface {
    var delegate: ViewModelDelegate?
    let daysInAWeek = 7

    // The id of a week points to the id of the first day of the week (which might be a Sunday or Monday, depending
    // on the preferences of the observing user. But this id is transient so that's okay
    var intId: Int {
        return Int(id!)!
    }

    convenience init(containingDayId dayId: String) {
        let beginningOfWeekId = dayId // should find the id of the beginning of the week i.e. Sunday
        self.init(id: beginningOfWeekId)
    }

    var weekAfter: WeekOverviewSurface {
        return WeekOverviewSurface(id: String(intId + daysInAWeek))
    }

    var weekBefore: WeekOverviewSurface {
        return WeekOverviewSurface(id: String(intId - daysInAWeek))
    }

    var days: [DaySurface] {
        var days = [DaySurface]()

        for i in 0...(daysInAWeek - 1) {
            days.append(DaySurface(dayId: intId + i))
        }

        return days
    }
}

class DaySurface {
    // how is this different from a day schedule view model? Does the day schedule view model end up using this to display things like the day name, etc.?

    init(dayId: Int) {
        self.dayId = dayId
    }

    var dayId: Int

    var weekdayName: String {
        let weekdaySymbols = Calendar.current.standaloneWeekdaySymbols // force gregorian here but change the locale? Maybe... maybe.
        let weekday = Calendar.current.dayOfTheWeek(for: GregorianDay(id: dayId))
        return weekdaySymbols[weekday]
    }

    var happensIn: TimePerspective {
        let today = Calendar.current.today

        if dayId > today.id {
            return .future
        }
        else if dayId < today.id {
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
