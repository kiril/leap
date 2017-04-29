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

        daySchedules = days.map { DayScheduleSurface.load(dayId: $0.id) }
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

    var weekRelativeDescription: String {
        let today = Calendar.current.today
        let thisWeek = WeekOverviewSurface(containingDayId: String(today.id))

        let weeksApart = ((intId - thisWeek.intId) / daysInAWeek)

        switch weeksApart {
        case 0:
            return "This Week"

        case 1:
            return "Next Week"

        case -1:
            return "Last Week"

        case let weeksApart where weeksApart > 1:
            return "\(weeksApart) Weeks Away"

        case let weeksApart where weeksApart < -1:
            return "\(abs(weeksApart)) Weeks Ago"

        default:
            return ""
        }
    }

    var days: [DaySurface] {
        var days = [DaySurface]()

        for i in 0...(daysInAWeek - 1) {
            days.append(DaySurface(id: String(intId + i)))
        }

        return days
    }

    var daySchedules: [DayScheduleSurface]!
}
