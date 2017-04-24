//
//  DayScheduleSurface.swift
//  Leap
//
//  Created by Chris Ricca on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit
import RealmSwift

class DayScheduleSurface: Surface {

    override var type: String { return "daySchedule" }

    let events = SurfaceProperty<[EventSurface]>()
    let series = SurfaceProperty<[SeriesSurface]>()
    let reminders = ComputedSurfaceProperty<[ReminderSurface],DayScheduleSurface>(by: DayScheduleSurface.computeReminders)

    static func computeReminders(daySchedule: DayScheduleSurface) -> [ReminderSurface] {
        return [ReminderSurface]()
    }

    var day: DaySurface { return DaySurface(id: self.id) }

    var filteredEventSeries: [SeriesSurface] {
        var matches: [SeriesSurface] = []
        for s in series.value {
            guard s.seriesType.value == .event else {
                continue
            }
            if s.recursOn(self.day.gregorianDay) {
                matches.append(s)
            }
        }
        return matches
    }

    private var _events: [EventSurface] = [] {
        didSet { _didLoadInitialEvents = true }
    }
    private var _didLoadInitialEvents = false

    private var _freshEvents: [EventSurface]? = nil
    private var _lastCachedEvents: TimeInterval = 0
    private var _eventRefreshStarted: TimeInterval? = nil

    private func refreshEvents(async: Bool = true) {
        var events = self.events.value
        for seriesSurface in filteredEventSeries {
            if let eventSurface = seriesSurface.event(for: self.day.gregorianDay) {
                events.append(eventSurface)
            }
        }

        events = Array(Set<EventSurface>(events))

        events.sort { $0.startTime.value < $1.startTime.value }

        _freshEvents = events
        _lastCachedEvents = Date.timeIntervalSinceReferenceDate

        if async {
            DispatchQueue.main.async {
                self._events = self._freshEvents!
                self.notifyObserversOfChange()
            }
        } else {
            _events = _freshEvents!
            _eventRefreshStarted = Date.timeIntervalSinceReferenceDate
            self.notifyObserversOfChange()
        }
    }

    private func checkEventFreshness(async: Bool = true) {
        if let startTime = _eventRefreshStarted, Date.timeIntervalSinceReferenceDate - startTime < 500.0 {
            return
        }

        if let updateTime = lastPersisted, _lastCachedEvents < updateTime {
            _eventRefreshStarted = Date.timeIntervalSinceReferenceDate
            if async {
                DispatchQueue.global(qos: .background).async {
                    usleep(100*1000) // sleep 100ms to de-bounce this function being called
                    self.refreshEvents()
                    self._eventRefreshStarted = nil
                }
            } else {
                refreshEvents(async: false)
                _eventRefreshStarted = nil
            }
        }
    }

    var entries: [ScheduleEntry] {
        guard _didLoadInitialEvents else { return [ScheduleEntry]() }
        
        DispatchQueue.global(qos: .background).async { self.checkEventFreshness() }

        let events = self.events(showingHidden: displayHiddenEvents)

        return scheduleEntriesForEvents(events: events)
    }

    private func events(showingHidden: Bool) -> [EventSurface] {
        return _events.filter() { (event) -> Bool in
            switch displayableType(forEvent: event) {
            case .always:
                return true
            case .sometimes:
                return showingHidden
            case .never:
                return false
            }
        }
    }

    private var normalScheduleRange: TimeRange {
        let scheduleStartHour = 9 // 9am
        let scheduleEndHour = 22 // 10pm

        let dayStart = Calendar.current.startOfDay(for: self.day.gregorianDay)
        let scheduleStart = Calendar.current.date(byAdding: DateComponents(hour: scheduleStartHour),
                                                  to: dayStart,
                                                  wrappingComponents: false)!
        let scheduleEnd = Calendar.current.date(byAdding: DateComponents(hour: scheduleEndHour),
                                                to: dayStart,
                                                wrappingComponents: false)!

        return TimeRange(start: scheduleStart,
                         end: scheduleEnd)!
    }

    private func
        scheduleEntriesForEvents(events: [EventSurface]) -> [ScheduleEntry] {
        var openTimeRanges = [normalScheduleRange]

        for event in events {
            guard let range = event.range else { continue }
            openTimeRanges = openTimeRanges.timeRangesByExcluding(timeRange: range)
        }

        openTimeRanges = openTimeRanges.filter { (timeRange) -> Bool in
            return timeRange.durationInSeconds >= (60 * 30) // only keep ranges > 30 minutes
        }

        let openTimeEntries = openTimeRanges.map{ ScheduleEntry.from(openTimeStart: $0.start, end: $0.end) }
        let eventEntries = events.map { ScheduleEntry.from(event: $0) }

        var theEntries = openTimeEntries + eventEntries

        theEntries.sort()

        return theEntries
    }

    var hideableEventsCount: Int {
        return _events.filter() { (event) -> Bool in
            return displayableType(forEvent: event) == .sometimes
        }.count
    }

    var hasHideableEvents: Bool {
        return hideableEventsCount > 0
    }

    var enableHideableEventsButton: Bool {
        return hasHideableEvents
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
        DispatchQueue.global(qos: .background).async { schedule.checkEventFreshness() }
        return schedule
    }

    var displayHiddenEvents: Bool = false {
        didSet {
            notifyObserversOfChange()
        }
    }

    func toggleHiddenEvents(){
        displayHiddenEvents = !displayHiddenEvents
    }

    var textForHiddenButton: String {
        guard hasHideableEvents else { return "No Hidden Events" }
        return displayHiddenEvents ? "Hide \"Maybe\" Events" : "Show \(hideableEventsCount) \"Maybe\" Event\(hideableEventsCount > 1 ? "s" : "")"
    }

    private func displayableType(forEvent event: EventSurface) -> EventDisplayableType {
        if event.userResponse.value == EventResponse.no {
            return .never
        }
        else if event.isConfirmed.value || event.needsResponse.value {
            return .always
        }
        return .sometimes
    }

    override func shouldNotifyObserversAboutChange(to updatedKey: String) -> Bool {
        if updatedKey == series.key || updatedKey == events.key {
            DispatchQueue.global(qos: .background).async { self.checkEventFreshness() }
            return false
        }
        return true
    }

    private enum EventDisplayableType {
        case always, sometimes, never
    }
}
