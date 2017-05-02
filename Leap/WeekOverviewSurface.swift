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
    let daysInAWeek = 7
    var intId: Int = 0
    
    convenience required init(intId: Int) {
        self.init(id: String(intId))
        self.intId = intId
    }

    // The id of a week points to the id of the first day of the week (which might be a Sunday or Monday, depending
    // on the preferences of the observing user. But this id is transient so that's okay

    convenience init(containingDayId dayId: Int) {
        let targetDay = DaySurface(id: String(dayId))

        let beginningOfWeekId = dayId - targetDay.weekdayIndex

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
        let dayId = Calendar.current.today.id
        let thisWeek = containsDay(dayId: dayId) ? self : WeekOverviewSurface(containingDayId: dayId)

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

    struct DayBusyness {
        var committedDaytime: CGFloat = 0
        var unresolvedDaytime: CGFloat = 0

        var committedEvening: CGFloat = 0
        var unresolvedEvening: CGFloat = 0
    }

    var weekBusyness = [1,2,3,4,5,6,7].map { _ in DayBusyness() }

    func containsDay(dayId: Int) -> Bool {
        return dayId >= self.intId && dayId < self.intId + 7
    }

    private var loadedWeekBusyness = false
    func loadWeekBusyness() {
        guard !loadedWeekBusyness else { return }
        loadedWeekBusyness = true

        let dayIds: [Int] = days.map { $0.intId }
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let surface = self

            for (index, id) in dayIds.enumerated() {
                guard surface != nil else { break }
                let schedule = DayScheduleSurface.load(dayId: id, withNotifications: false)
                let busy = DayBusyness(
                    committedDaytime: schedule.percentBooked(forType: .committed, during: .day),
                    unresolvedDaytime: schedule.percentBooked(forType: .committedAndUnresolved, during: .day),
                    committedEvening: schedule.percentBooked(forType: .committed, during: .evening),
                    unresolvedEvening: schedule.percentBooked(forType: .committedAndUnresolved, during: .evening)
                )
                DispatchQueue.main.async() {
                    surface?.weekBusyness[index] = busy
                    surface?.notifyObserversOfChange()
                }
            }
        }
    }
}
