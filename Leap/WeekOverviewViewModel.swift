//
//  WeekOverviewViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import UIKit

class WeekOverviewViewModel: ViewModelUpdateable {
    var delegate: ViewModelDelegate?
    let daysInAWeek = 7

    let id: Int // identified by the dayId of the starting day (i.e. the last occuringSunday)

    init(id: Int) {
        self.id = id
    }

    init(containingDayId dayId: Int) {
        let beginningOfWeekId = dayId // should find the id of the beginning of the week i.e. Sunday
        self.id = beginningOfWeekId
    }

    var weekAfter: WeekOverviewViewModel {
        return WeekOverviewViewModel(id: self.id + daysInAWeek)
    }

    var weekBefore: WeekOverviewViewModel {
        return WeekOverviewViewModel(id: self.id - daysInAWeek)
    }

    var days: [DayViewModel] {
        var days = [DayViewModel]()

        for i in 0...(daysInAWeek - 1) {
            days.append(DayViewModel(dayId: id + i))
        }

        return days
    }
}

class DayViewModel {
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
        today = Calendar.current.today

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
        return perspective == .current
    }
}
