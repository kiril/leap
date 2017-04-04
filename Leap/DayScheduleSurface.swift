//
//  DayScheduleSurface.swift
//  Leap
//
//  Created by Chris Ricca on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

class DayScheduleSurface: Surface {

    override var type: String { return "dayScheduleSurface" }

    private let eventStore = EKEventStore() // should do this once per app load instead... somewhere?

    let entries = ComputedProperty<[ScheduleEntry], DayScheduleSurface>("entries", DayScheduleSurface.scheduleEntries)

    let day = ComputedProperty<DaySurface, DayScheduleSurface>("day", DayScheduleSurface.daySurface)

    var numberOfEntries: Int {
        return entries.value.count
    }

    private static func scheduleEntries(schedule: DayScheduleSurface) -> [ScheduleEntry] {
        return [ScheduleEntry]()
    }

    private static func daySurface(schedule: DayScheduleSurface) -> DaySurface {
        return DaySurface(id: schedule.id)
    }

    var dateDescription: String {
        let day = self.day.value
        return "\(day.monthNameShort) \(day.dayOfTheMonth), \(day.year)"
    }

    var weekdayDescription: String {
        let day = self.day.value
        let weekday = day.weekdayName

        let today = Calendar.current.today
        if day.intId == today.id { return "Today (\(weekday))" }
        if day.intId == today.id + 1 { return "Tomorrow (\(weekday))" }
        if day.intId == today.id - 1 { return "Yesterday (\(weekday))" }
        return weekday
    }
//
//    var subtitle: String {
//
//    }
}
