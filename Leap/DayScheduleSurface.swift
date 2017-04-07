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

    let events = SurfaceProperty<[EventSurface]>()
    var day: DaySurface { return DaySurface(id: self.id) }
    var entries: [ScheduleEntry] {
        return hackyDeduped(events.value).map { event in ScheduleEntry.from(event: event) }
    }

    func hackyHash(_ event: EventSurface) -> String {
        return "\(event.title.value)_\(event.startTime.value)_\(event.endTime.value)"
    }

    func hackyDeduped(_ events: [EventSurface]) -> [EventSurface] {
        var deduped: [EventSurface] = []
        var seenHashes: Set<String> = []
        for event in events {
            let eventHash = hackyHash(event)
            if !seenHashes.contains(eventHash) {
                seenHashes.update(with: eventHash)
                deduped.append(event)
            }
        }
        return deduped
    }

    var numberOfEntries: Int {
        return hackyDeduped(events.value).count
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

    static func load<K:KeyConvertible>(dayId genericKey: K) -> DayScheduleSurface {
        let schedule = DayScheduleSurface(id: genericKey.toKey())
        let bridge = SurfaceModelBridge<DayScheduleSurface>(id: genericKey.toKey(), surface: schedule)

        let start = Calendar.current.startOfDay(for: schedule.day.gregorianDay)
        let end = Calendar.current.startOfDay(for: schedule.day.gregorianDay.dayAfter)
        let events = Event.between(start, and: end)
        bridge.referenceArray(events, using: EventSurface.self, as: "events")
        bridge.bindArray(schedule.events)
        schedule.store = bridge
        bridge.populate(schedule)
        return schedule
    }
}
