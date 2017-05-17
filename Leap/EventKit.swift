//
//  EventKit.swift
//  Leap
//
//  Created by Kiril Savino on 4/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit
import RealmSwift

let importQueue = DispatchQueue(label: "eventkit.import")

class EventKit {
    let store: EKEventStore

    init(store: EKEventStore) {
        self.store = store
    }

    func firstTime() -> Bool {
        return Realm.user().objects(Event.self).isEmpty
    }

    private func doImport(from start: Date, to end: Date) {
        store.calendars(for: EKEntityType.event).forEach { self.importEvents(in: $0, from: start, to: end) }
        store.calendars(for: EKEntityType.reminder).forEach { self.importEvents(in: $0, from: start, to: end) }
    }

    func catchUp() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.dayAfter(startOfDay)
        let aWeekOut = Calendar.current.adding(days: 7, to: endOfDay)
        let aWeekBack = Calendar.current.subtracting(days: 7, from: startOfDay)

        doImport(from: endOfDay, to: aWeekOut)
        doImport(from: startOfDay, to: endOfDay)
        doImport(from: aWeekBack, to: startOfDay)
        doImport(from: aWeekOut, to: farOffFuture())
    }

    func importAll() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.startOfDay(for: Calendar.current.dayAfter(startOfDay))
        let aWeekOut = Calendar.current.adding(days: 7, to: endOfDay)
        let aWeekBack = Calendar.current.subtracting(days: 7, from: startOfDay)

        doImport(from: endOfDay, to: aWeekOut) // doing immediate future first helps stop recurring event thrash
        doImport(from: startOfDay, to: endOfDay) // then we populate today quickly
        doImport(from: aWeekBack, to: startOfDay) // then recent past

        doImport(from: aWeekOut, to: farOffFuture()) // the rest
        doImport(from: longAgo(), to: startOfDay) // of time (as we know it)
    }

    // max sync distance is 4 years
    func longAgo() -> Date {
        let endOfToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let minus4years = DateComponents(calendar: Calendar.current, year: -4)
        return Calendar.current.date(byAdding: minus4years, to: endOfToday, wrappingComponents: true)!
    }

    // max sync distance is 4 years
    func farOffFuture() -> Date {
        let startOfToday = Calendar.current.startOfDay(for: Calendar.current.today)
        let plus4years = DateComponents(calendar: Calendar.current, year: 4)
        return Calendar.current.date(byAdding: plus4years, to: startOfToday, wrappingComponents: true)!
    }

    func importEvents(in calendar: EKCalendar, from: Date, to: Date) {
        calendar.asLegacyCalendar(eventStoreId: store.eventStoreIdentifier).update()
        store.enumerateEvents(in: calendar, from: from, to: to, using: eventSearchCallback(calendar))
    }

    func eventSearchCallback(_ calendar: EKCalendar) -> EKEventSearchCallback {
        return { (event:EKEvent, stop:UnsafeMutablePointer<ObjCBool>) in self.importEK(event: event, in: calendar) }
    }

    func importEK(event ekEvent: EKEvent, in calendar: EKCalendar) {
        importQueue.async {
            if let series = Series.by(id: ekEvent.cleanId) { // always keep series as series, even if arrives w/o recurrence info
                self.importSeries(ekEvent, in: calendar, given: series)

            } else {

                if ekEvent.isRecurring {
                    let existing = Series.by(id: ekEvent.cleanId)
                    self.importSeries(ekEvent, in: calendar, given: existing)

                } else {
                    switch ekEvent.type {
                    case .event:
                        let existing = Event.by(id: ekEvent.cleanId)
                        self.importOne(ekEvent, in: calendar, given: existing)

                    case .reminder:
                        if let series = Series.by(title: ekEvent.title),
                            (series.recurs(exactlyAt: ekEvent.startDate) || (ekEvent.isAllDay && series.recurrence.recurs(on: ekEvent.startDate, for: series))) {
                            print("reminder DUPLICATE of Series \(ekEvent.title)")
                            self.importSeries(ekEvent, in: calendar, given: series)

                        } else if ekEvent.isMultidayReminder {
                            self.importSeries(ekEvent, in: calendar)

                        } else {
                            let existing = Reminder.by(id: ekEvent.cleanId)
                            self.importOne(ekEvent, in: calendar, given: existing)
                        }
                    }
                }
            }
        }
    }

    func merge(_ ekEvent: EKEvent, into another: Temporality, in calendar: EKCalendar, detached: Bool = false, from series: Series? = nil) {
        var existing = another
        let origin = ekEvent.getOrigin(in: calendar)

        let realm = Realm.user()
        if existing.participants.isEmpty && ekEvent.hasAttendees {
            try! realm.safeWrite {
                existing.addParticipants(ekEvent.getParticipants(origin: origin))
                existing.status = ekEvent.objectStatus
            }
        }

        let bestOrigin = existing.origin.winner(vs: origin)
        if bestOrigin != existing.origin {
            try! realm.safeWrite {
                print("\(ekEvent.title) -> \(bestOrigin)")
                existing.origin = bestOrigin
            }
        }

        if !existing.wasDetached && detached {
            if let event = existing as? Event {
                try! realm.safeWrite {
                    event.wasDetached = true
                }
            } else if let reminder = existing as? Reminder {
                try! realm.safeWrite {
                    reminder.wasDetached = true
                }
            }
        }

        if let linkable = existing as? CalendarLinkable {
            try! realm.safeWrite {
                linkable.addLink(to: calendar)
            }
        }
        print("\(String(describing: type(of:existing)).lowercased()) UPDATE \(ekEvent.title)")
    }

    func importOne<T:LeapModel>(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: T? = nil, detached: Bool = false, from series: Series? = nil, eventId: String? = nil) where T:Temporality, T:Fuzzy {
        if let existing = existing {
            merge(ekEvent, into: existing, in: calendar)
            return
        }

        var item: Temporality!
        if T.self == Event.self {
            item = ekEvent.asEvent(in: calendar, detached: detached, from: series, eventId: eventId)
        } else {
            item = ekEvent.asReminder(in: calendar, detached: detached, from: series, eventId: eventId)
        }

        if detached && item.id != ekEvent.cleanId, let existingDetached = T.by(id: item.id) {
            merge(ekEvent, into: existingDetached, in: calendar)
            return
        }

        if let duplicate = T.by(fuzzyHash: (item as! Fuzzy).calculateFuzzyHash()) {
            print("\(String(describing: T.self).lowercased()) DUPLICATE \(ekEvent.title)")
            merge(ekEvent, into: duplicate, in: calendar, detached: detached, from: series)

        } else {
            print("event INSERT \(ekEvent.title) \(item.origin) [\(item.wasDetached)] \(DateFormatter.shortDate(item.date!)) from \(calendar.title)")
            (item as! LeapModel).insert()
        }
    }

    func merge(_ ekEvent: EKEvent, into existing: Series, in calendar: EKCalendar) {

        try! Realm.user().safeWrite {
            existing.updateStartTimeIfEarlier(ekEvent.startDate.secondsSinceReferenceDate)
            existing.template.addParticipants(ekEvent.getParticipants(origin: ekEvent.getOrigin(in: calendar)))
            existing.template.addLink(to: calendar)
            existing.template.addAlarms(ekEvent.getAlarms())
            if existing.status == .archived && ekEvent.objectStatus == .active {
                existing.status = .active
            }

            let origin = ekEvent.getOrigin(in: calendar)
            let best = origin.winner(vs: existing.origin)
            if origin != existing.origin {
                var series = existing
                series.updateToBestOrigin(with: best)
                series.template.updateToBestOrigin(with: best)
            }
        }

        if existing.title.contains("Kids Overnight") {
            print(existing.recurrence)
            print(existing.template)
            print(existing.startDate)
            let end = existing.endDate
            print(end == nil ? "No End" : String(describing: end))
            print("Yup here we are")
        }

        print("series UPDATE \(existing.type) \(ekEvent.title) \(existing.status)")
    }

    func cleanUp(after series: Series) {

        if let event = Event.by(id: series.id) {
            if event.isDetachedForm(of: series) && !event.wasDetached {
                let detached = Event(value: event)
                if let id = series.generateId(in: TimeRange.day(of: detached.startDate)) {
                    print("event DETACH modified series root \(event.title), \(DateFormatter.shortDate(event.startDate))")
                    detached.seriesId = series.id
                    detached.id = id
                    detached.insert()
                }
            } else {
                print("event DELETE series root \(event.title)")
            }

            event.delete()
        }

        if let reminder = Reminder.by(id: series.id) {
            if reminder.isDetachedForm(of: series) && !reminder.wasDetached {
                let detached = Reminder(value: reminder)
                if let id = series.generateId(in: TimeRange.day(of: detached.startDate)) {
                    print("event DETACH modified series root \(reminder.title), \(DateFormatter.shortDate(reminder.startDate))")
                    detached.seriesId = series.id
                    detached.id = id
                    detached.insert()
                }
            } else {
                print("event DELETE series root \(reminder.title)")
            }

            reminder.delete()
        }
    }

    func eventExists(withId id: String, in calendar: EKCalendar, during range: TimeRange) -> Bool {
    }

    func findOriginalDate(in series: Series, for event: EKEvent) -> Date? {
        var earlier: Date?
        var later: Date?

        if let before = series.lastRecurringDate(before: event.startDate),
            eventExists(withId: series.id, in: event.calendar, during: TimeRange.day(of: before)) {
            earlier = before
        }
        if let after = series.nextRecurringDate(after: event.startDate),
            eventExists(withId: series.id, in: event.calendar, during: TimeRange.day(of: after)) {
            later = after
        }

        if let earlier = earlier, later == nil {
            return earlier

        } else if let later = later, earlier == nil {
            return later

        } else if let later = later, let earlier = earlier {
            let laterDays = Calendar.current.daysBetween(event.startDate, and: later)
            let earlierDays = Calendar.current.daysBetween(earlier, and: event.startDate)
            if laterDays < earlierDays {
                return later
            } else if earlierDays < laterDays {
                return earlier
            }
        }

        return nil
    }

    func findDetachedIdentifier(in series: Series, near date: Date) -> String? {
        guard let originalDate = findOriginalDate(in: series, near: date) else { return nil }
        return series.generateId(for: originalDate)
    }

    func importSeries(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Series? = nil) {

        if let series = existing {
            if ekEvent.isDetachedForm(of: series) {
                guard let id = series.generateId(forDayOf: ekEvent.startDate) ?? findDetachedIdentifier(in: series, near: ekEvent.startDate) else {
                    print("series BROKEN detached/can't figure out where from \(ekEvent.title)")
                    return
                }

                switch ekEvent.type {
                case .event:
                    print("event DETACHING from \(series.title) for \(DateFormatter.shortDate(ekEvent.startDate))")
                    let event = Event.by(id: id)
                    importOne(ekEvent, in: calendar, given: event, detached: true, from: series, eventId: id)

                case .reminder:
                    let reminder = Reminder.by(id: id)
                    print("reminder DETACHING from \(series.title) for \(DateFormatter.shortDate(ekEvent.startDate))")
                    importOne(ekEvent, in: calendar, given: reminder, detached: true, from: series, eventId: id)
                }

            } else {
                merge(ekEvent, into: series, in: calendar)
            }

        } else if let rule = ekEvent.rule {
            let series = rule.asSeries(for: ekEvent, in: calendar)
            if let duplicate = Series.by(fuzzyHash: series.calculateFuzzyHash()) {
                print("series DUPLICATE \(duplicate.title)")
                merge(ekEvent, into: duplicate, in: calendar)

            } else {
                if let me = series.template.me, me.engagement == .disengaged {
                    series.status = .archived
                }
                print("series INSERT \(series.type) \(ekEvent.title) \(series.status)")
                series.insert()
                cleanUp(after: series)
            }

        } else if ekEvent.isMultidayReminder {
            let series = ekEvent.asSeries(in: calendar)
            print("series INSERT spanning-reminder \(ekEvent.title) \(series.status)")
            series.insert()
        }
    }
}
