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
    let reminders = SurfaceProperty<[ReminderSurface]>()

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

    var filteredReminderSeries: [SeriesSurface] {
        var matches: [SeriesSurface] = []
        for s in series.value {
            guard s.seriesType.value == .reminder else {
                continue
            }
            if s.recursOn(self.day.gregorianDay) {
                matches.append(s)
            }
        }
        return matches
    }

    func isLessThan(left: EventSurface, right: EventSurface) -> Bool {
        if left.arrivalTime.value < right.arrivalTime.value {
            return true
        }
        if right.arrivalTime.value < left.arrivalTime.value {
            return false
        }
        if left.isConfirmed.value && !right.isConfirmed.value {
            return true
        }
        if right.isConfirmed.value && !left.isConfirmed.value {
            return false
        }
        if left.departureTime.value < right.departureTime.value {
            return true
        }
        if right.departureTime.value < left.departureTime.value {
            return false
        }

        return false
    }

    private var cachedCombinedEvents: [EventSurface]? = nil
    private var combinedEvents: [EventSurface] {
        if let cache = cachedCombinedEvents { return cache }
        var events = self.events.value
        for seriesSurface in filteredEventSeries {
            if let eventSurface = seriesSurface.event(for: self.day.gregorianDay) {
                events.append(eventSurface)
            }
        }

        events = Array(Set<EventSurface>(events))

        events.sort(by: isLessThan)

        var secondPriorEvent: EventSurface? = nil
        var priorEvent: EventSurface? = nil

        for event in events {
            event.isInConflict = false

            guard event.isEligibleForConflict else { continue }

            var priorToUse: EventSurface? = nil
            if let p = priorEvent, p.isEligibleForConflict {
                priorToUse = p
            } else if let p = secondPriorEvent, p.isEligibleForConflict {
                priorToUse = p
            }

            if let prior = priorToUse {
                if event.conflicts(with: prior) {
                    event.isInConflict = true
                }
                if prior.conflicts(with: event) {
                    prior.isInConflict = true
                }
            }

            secondPriorEvent = priorEvent
            priorEvent = event
        }

        return events
    }


    private var cachedCombinedReminders: [ReminderSurface]?
    private var combinedReminders: [ReminderSurface] {
        if let cache = cachedCombinedReminders { return cache }

        var reminders = self.reminders.value
        for seriesSurface in filteredReminderSeries {
            if let reminderSurface = seriesSurface.reminder(for: self.day.gregorianDay) {
                reminders.append(reminderSurface)
            }
        }

        reminders = Array(Set<ReminderSurface>(reminders))

        reminders.sort { $0.startTime.value < $1.startTime.value }

        return reminders
    }

    var entries: [ScheduleEntry] {
        let events = self.events(showingHidden: displayHiddenEvents)
        var hiddenEvents = [EventSurface]()

        if !displayHiddenEvents {
            // events to possibly display in open time
            hiddenEvents = hideableEvents()
        }
        return scheduleEntries(displayedEvents: events,
                               possibleEvents: hiddenEvents)
    }

    var reminderList: [ReminderSurface] {
        return combinedReminders
    }

    private func events(showingHidden: Bool) -> [EventSurface] {
        return combinedEvents.filter() { (event) -> Bool in
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

    private func hideableEvents() -> [EventSurface] {
        return combinedEvents.filter() { (event) -> Bool in
            return self.displayableType(forEvent: event) == .sometimes
        }
    }

    private func reminders(showingHidden: Bool) -> [ReminderSurface] {
        return combinedReminders.filter() { (reminder) -> Bool in
            switch displayableType(forReminder: reminder) {
            case .always:
                return true
            case .sometimes:
                return showingHidden
            case .never:
                return false
            }
        }
    }

    private var fullScheduleRange: TimeRange {
        return timeRanges(from: 9, to: 22)! // 9am - 10pm
    }
    private var daytimeScheduleRange: TimeRange {
        return timeRanges(from: 9, to: 18)! // 9am - 6pm
    }
    private var eveningScheduleRange: TimeRange {
        return timeRanges(from: 18, to: 24)! // 6am - midnight
    }

    private func timeRanges(from startHour: Int, to endHour: Int) -> TimeRange? {
        let dayStart = Calendar.current.startOfDay(for: self.day.gregorianDay)
        let rangeStart = Calendar.current.date(byAdding: DateComponents(hour: startHour),
                                                  to: dayStart,
                                                  wrappingComponents: false)!
        let rangeEnd = Calendar.current.date(byAdding: DateComponents(hour: endHour),
                                                to: dayStart,
                                                wrappingComponents: false)!

        return TimeRange(start: rangeStart,
                         end: rangeEnd)
    }

    private func scheduleEntries(displayedEvents: [EventSurface],
                                 possibleEvents: [EventSurface] = [EventSurface]()) -> [ScheduleEntry] {
        let openTimeRanges = displayedEvents.openTimes(in: fullScheduleRange).filter { (timeRange) -> Bool in
            return timeRange.durationInSeconds >= (60 * 30) // only keep ranges > 30 minutes
        }

        var openTimeEntries = [ScheduleEntry]()
        let sortedPossibleEvents = possibleEvents.sorted()
        for openRange in openTimeRanges {
            var openTime = OpenTimeViewModel(startTime: openRange.start, endTime: openRange.end)
            for possibleEvent in sortedPossibleEvents {
                guard let eventRange = possibleEvent.range else { continue }

                if eventRange.isWithin(timeRange: openRange) {
                    openTime.possibleEventIds.append(possibleEvent.id)
                }
            }
            openTimeEntries.append(ScheduleEntry.from(openTime: openTime))
        }

        let eventEntries = displayedEvents.map { ScheduleEntry.from(event: $0) }

        var theEntries = openTimeEntries + eventEntries

        theEntries.sort()

        return theEntries
    }

    enum DayBusynessSection { case day, evening }
    enum DayBusynessEventType { case committed, committedAndUnresolved }
    // returns 0.0 - 1.0 for percent booked display
    func percentBooked(forType eventType: DayBusynessEventType,
                       during daySection: DayBusynessSection) -> CGFloat {

        let totalTimeRange = daySection == .day ? daytimeScheduleRange : eveningScheduleRange
        let events = self.combinedEvents.filter { (event) -> Bool in
            switch eventType {
            case .committedAndUnresolved:
                return displayableType(forEvent: event) == .always
            case .committed:
                return event.userResponse.value == .yes
            }
        }
        let openTimeInSeconds = events.openTimes(in: totalTimeRange).combinedDurationInSeconds
        return CGFloat(1.0 - (openTimeInSeconds / totalTimeRange.durationInSeconds))
    }

    var hideableEventsCount: Int {
        return combinedEvents.filter() { (event) -> Bool in
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

    static func load<K:KeyConvertible>(dayId genericKey: K, withNotifications: Bool = true) -> DayScheduleSurface {
        let schedule = DayScheduleSurface(id: genericKey.toKey())
        let bridge = SurfaceModelBridge(id: genericKey.toKey(), surface: schedule)

        let start = Calendar.current.startOfDay(for: schedule.day.gregorianDay)
        let end = Calendar.current.startOfDay(for: schedule.day.gregorianDay.dayAfter)

        let events = Event.between(start, and: end)
        let series = Series.between(start, and: end)
        let reminders = Reminder.between(start, and: end)

        bridge.referenceArray(events, using: EventSurface.self, as: "events", withNotifications: withNotifications)
        bridge.referenceArray(series, using: SeriesSurface.self, as: "series", withNotifications: withNotifications)
        bridge.referenceArray(reminders, using: ReminderSurface.self, as: "reminders", withNotifications: withNotifications)

        bridge.bindArray(schedule.events)
        bridge.bindArray(schedule.series)
        bridge.bindArray(schedule.reminders)

        schedule.store = bridge
        bridge.populate(schedule)

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

    private func displayableType(forReminder reminder: ReminderSurface) -> EventDisplayableType {
        return .always
    }

    override func shouldNotifyObserversAboutChange(to updatedKey: String) -> Bool {
        guard lastPersisted != nil else {
            return false
        }

        if updatedKey == series.key || updatedKey == events.key {
            cachedCombinedEvents = nil // clear cache
        }
        if updatedKey == series.key || updatedKey == reminders.key {
            cachedCombinedReminders = nil // clear cache
        }

        return true
    }

    private enum EventDisplayableType {
        case always, sometimes, never
    }
}

extension Array where Element: Schedulable {
    var events: [EventSurface] {
        var ret: [EventSurface] = []
        for entry in (self as! [ScheduleEntry]) {
            switch entry {
            case let .event(event):
                ret.append(event)
            default:
                continue
            }
        }
        return ret
    }
}
