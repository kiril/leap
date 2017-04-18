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

    private var _entries: [ScheduleEntry] = []
    private var _freshEntries: [ScheduleEntry]? = nil
    private var _lastCachedEntries: TimeInterval = 0
    private var _entryRefreshStarted: TimeInterval? = nil

    private func refreshEntries(async: Bool = true) {
        var entries = events.value.map { event in ScheduleEntry.from(event: event) }
        for seriesSurface in filteredSeries {
            if let eventSurface = seriesSurface.event(for: self.day.gregorianDay) {
                entries.append(ScheduleEntry.from(event: eventSurface))
            }
        }
        entries.sort { $0 < $1 }
        _freshEntries = entries
        _lastCachedEntries = Date.timeIntervalSinceReferenceDate

        if async {
            DispatchQueue.main.async {
                self._entries = self._freshEntries!
                self.notifyObserversOfChange()
            }
        } else {
            _entries = _freshEntries!
            _entryRefreshStarted = Date.timeIntervalSinceReferenceDate
        }
    }

    private func checkEntryFreshness(async: Bool = true) {
        if let startTime = _entryRefreshStarted, Date.timeIntervalSinceReferenceDate - startTime < 500.0 {
            return
        }

        if let updateTime = lastPersisted, _lastCachedEntries < updateTime {
            _entryRefreshStarted = Date.timeIntervalSinceReferenceDate
            if async {
                DispatchQueue.global(qos: .background).async {
                    usleep(100*1000) // sleep 100ms to de-bounce this function being called
                    self.refreshEntries()
                    self._entryRefreshStarted = nil
                }
            } else {
                refreshEntries(async: false)
                _entryRefreshStarted = nil
            }
        }
    }

    var entries: [ScheduleEntry] {
        if _lastCachedEntries == 0 {
            checkEntryFreshness(async: false)
        }
        DispatchQueue.global(qos: .background).async { self.checkEntryFreshness() }
        return _entries
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

    var displayHiddenEvents: Bool = false

    private var hiddenEvents: [EventSurface] {
        return [EventSurface]()
    }

    private func willHideWhenHidden(event: EventSurface) -> Bool {
//        if event.needs
        return false
    }

//    private var hasHiddenEvents: Bool {
//        return hideableEvents.count > 0
//    }

//    var shouldShow
}
