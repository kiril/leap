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

    func importAll() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.startOfDay(for: Calendar.current.dayAfter(startOfDay))
        let aWeekAway = Calendar.current.date(byAdding: .day, value: 7, to: endOfDay)!

        // some future first, because recurring events are annoying, and this stops some thrash
        store.calendars(for: EKEntityType.event).forEach { self.importEvents(in: $0, from: endOfDay, to: aWeekAway) }
        store.calendars(for: EKEntityType.reminder).forEach { self.importEvents(in: $0, from: endOfDay, to: aWeekAway) }

        // get today's stuff flowing in fast
        store.calendars(for: EKEntityType.event).forEach { self.importEvents(in: $0, from: startOfDay, to: endOfDay) }
        store.calendars(for: EKEntityType.reminder).forEach { self.importEvents(in: $0, from: startOfDay, to: endOfDay) }

        // future, because you're more likely to look there soon
        store.calendars(for: EKEntityType.event).forEach { self.importEvents(in: $0, from: aWeekAway, to: farOffFuture()) }
        store.calendars(for: EKEntityType.reminder).forEach { self.importEvents(in: $0, from: aWeekAway, to: farOffFuture()) }

        // then get the past (which cleans up some stuff about event recurrence, too)
        store.calendars(for: EKEntityType.event).forEach { self.importEvents(in: $0, from: longAgo(), to: startOfDay) }
        store.calendars(for: EKEntityType.reminder).forEach { self.importEvents(in: $0, from: longAgo(), to: startOfDay) }
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
        return { (event:EKEvent, stop:UnsafeMutablePointer<ObjCBool>) in self.importEvent(event, in: calendar) }
    }

    func importEvent(_ ekEvent: EKEvent, in calendar: EKCalendar) {
        importQueue.async {
            if let series = Series.by(id: ekEvent.cleanId) { // always keep series as series, even if arrives w/o recurrence info
                self.importAsSeries(ekEvent, in: calendar, given: series)

            } else {

                if ekEvent.isRecurring {
                    let existing = Series.by(id: ekEvent.cleanId)
                    self.importAsSeries(ekEvent, in: calendar, given: existing)

                } else {
                    switch ekEvent.type {
                    case .event:
                        let existing = Event.by(id: ekEvent.cleanId)
                        self.importAsEvent(ekEvent, in: calendar, given: existing)

                    case .reminder:
                        if let series = Series.by(title: ekEvent.title),
                            (series.recurs(on: ekEvent.startDate) || (ekEvent.isAllDay && series.recurrence.recursOn(ekEvent.startDate, for: series))) {
                            print("reminder DUPLICATE of Series \(ekEvent.title)")
                            self.importAsSeries(ekEvent, in: calendar, given: series)

                        } else {
                            let existing = Reminder.by(id: ekEvent.cleanId)
                            self.importAsReminder(ekEvent, in: calendar, given: existing)
                        }
                    }
                }
            }
        }
    }

    func merge(_ ekEvent: EKEvent, into another: Temporality, in calendar: EKCalendar, detached: Bool = false, from series: Series? = nil) {
        var existing = another
        let realm = Realm.user()
        if existing.participants.isEmpty && ekEvent.hasAttendees {
            try! realm.safeWrite {
                existing.addParticipants(ekEvent.getParticipants(origin: ekEvent.getOrigin(in: calendar)))
                existing.status = ekEvent.objectStatus
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

    func importAsEvent(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Event? = nil, detached: Bool = false, from series: Series? = nil) {
        if let existing = existing {
            merge(ekEvent, into: existing, in: calendar)

        } else {
            let event = ekEvent.asEvent(in: calendar, detached: detached, from: series)
            if let duplicate = Event.by(fuzzyHash: event.calculateFuzzyHash()) {
                print("event DUPLICATE \(ekEvent.title)")
                merge(ekEvent, into: duplicate, in: calendar, detached: detached, from: series)

            } else {
                event.insert()
                print("event INSERT \(ekEvent.title) \(event.origin) from \(calendar.title)")
                if ekEvent.title.contains("Eleni") {
                    print("    Calendar: \(calendar.title) - \(calendar.calendarIdentifier)")
                    print("    Source: \(calendar.source.title) - \(calendar.source.sourceIdentifier)")
                    print("    ID: \(ekEvent.eventIdentifier)")
                }
            }
        }
    }

    func importAsReminder(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Reminder? = nil, detached: Bool = false, from series: Series? = nil) {
        if let existing = existing {
            merge(ekEvent, into: existing, in: calendar)

        } else {
            let reminder = ekEvent.asReminder(in: calendar, detached: detached, from: series)
            if let duplicate = Reminder.by(fuzzyHash: reminder.calculateFuzzyHash()) {
                print("reminder DUPLICATE \(ekEvent.title)")
                merge(ekEvent, into: duplicate, in: calendar, detached: detached, from: series)

            } else {
                reminder.insert()
                print("reminder INSERT \(ekEvent.title) \(reminder.type)")
            }
        }
    }

    func merge(_ ekEvent: EKEvent, into existing: Series, in calendar: EKCalendar) {
        guard ekEvent.startDate < existing.startDate else {
            return
        }

        try! Realm.user().safeWrite {
            existing.updateStartTimeIfEarlier(ekEvent.startDate.secondsSinceReferenceDate)
            existing.template.addParticipants(ekEvent.getParticipants(origin: ekEvent.getOrigin(in: calendar)))
            existing.template.addLink(to: calendar)
            existing.template.addAlarms(ekEvent.getAlarms())
            if existing.status == .archived && ekEvent.objectStatus == .active {
                existing.status = .active
            }
        }

        print("series UPDATE \(existing.type) \(ekEvent.title) \(existing.status)")
    }

    func importAsSeries(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Series? = nil) {
        if let event = Event.by(id: ekEvent.cleanId), !event.wasDetached {
            event.delete()
            print("event DELETE series root \(ekEvent.title)")
        }
        if let reminder = Reminder.by(id: ekEvent.cleanId) {
            reminder.delete()
            print("reminder DELETE series root \(ekEvent.title)")
        }

        if let existing = existing {
            if ekEvent.isDetachedForm(of: existing) {
                switch ekEvent.type {
                case .event:
                    importAsEvent(ekEvent, in: calendar, given: Event.by(id: ekEvent.cleanId), detached: true, from: existing)
                case .reminder:
                    importAsReminder(ekEvent, in: calendar, given: Reminder.by(id: ekEvent.cleanId), detached: true, from: existing)
                }
            } else {
                merge(ekEvent, into: existing, in: calendar)
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
            }
        }
    }
}
