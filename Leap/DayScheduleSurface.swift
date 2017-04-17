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
    let series = SurfaceProperty<[SeriesSurface]>()
    var day: DaySurface { return DaySurface(id: self.id) }

    var filteredSeries: [SeriesSurface] {
        var matches: [SeriesSurface] = []
        for s in series.value {
            if s.recursOn(self.day.gregorianDay) {
                matches.append(s)
            }
        }
        return matches
    }

    private var _lastCachedEvents: TimeInterval? = nil
    private var _entriesCache: [ScheduleEntry]? = nil

    var entries: [ScheduleEntry] {
        if let cacheTime = _lastCachedEvents,
            let updateTime = lastPersisted,
            cacheTime > updateTime,
            let cache = _entriesCache {
            return cache
        }
        var entries = events.value.map { event in ScheduleEntry.from(event: event) }
        for seriesSurface in filteredSeries {
            if let eventSurface = seriesSurface.event(for: self.day.gregorianDay) {
                entries.append(ScheduleEntry.from(event: eventSurface))
            }
        }
        _entriesCache = entries
        _lastCachedEvents = Date.timeIntervalSinceReferenceDate
        return entries
    }

    var numberOfEntries: Int {
        return entries.count
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
        let bridge = SurfaceModelBridge(id: genericKey.toKey(), surface: schedule)

        let start = Calendar.current.startOfDay(for: schedule.day.gregorianDay)
        let end = Calendar.current.startOfDay(for: schedule.day.gregorianDay.dayAfter)
        let events = Event.between(start, and: end)
        let series = Series.between(start, and: end)
        bridge.referenceArray(events, using: EventSurface.self, as: "events")
        bridge.referenceArray(series, using: SeriesSurface.self, as: "series")
        bridge.bindArray(schedule.events)
        bridge.bindArray(schedule.series)
        schedule.store = bridge
        bridge.populate(schedule)
        return schedule
    }
}
