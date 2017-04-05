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

    override var type: String { return "daySchedule" }

    let events = SurfaceProperty<[EventSurface]>("events")
    var day: DaySurface { return DaySurface(id: self.id) }
    var entries: [ScheduleEntry] {
        return events.value.map { event in ScheduleEntry.from(event: event) }
    }

    var numberOfEntries: Int {
        return events.value.count
    }

    private static func daySurface(schedule: DayScheduleSurface) -> DaySurface {
        return DaySurface(id: schedule.id)
    }

    var dateDescription: String {
        return "\(day.monthNameShort) \(day.dayOfTheMonth), \(day.year)"
    }

    var weekdayDescription: String {
        let weekday = day.weekdayName

        let today = Calendar.current.today
        if day.intId == today.id { return "Today (\(weekday))" }
        if day.intId == today.id + 1 { return "Tomorrow (\(weekday))" }
        if day.intId == today.id - 1 { return "Yesterday (\(weekday))" }
        return weekday
    }

    static func load(dayId: Int) -> DayScheduleSurface {
        let schedule = DayScheduleSurface(id: String(dayId))
        let bridge = SurfaceModelBridge(id: String(dayId))
        let start = Calendar.current.startOfDay(for: schedule.day.gregorianDay)
        let end = Calendar.current.startOfDay(for: schedule.day.gregorianDay.dayAfter)
        let events = Event.between(start, and: end)
        bridge.reference(events, using: EventSurface.self, as: "events")
        schedule.store = bridge
        return schedule
    }
}
