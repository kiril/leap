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

class EventKit {
    let store: EKEventStore

    init(store: EKEventStore) {
        self.store = store
    }

    func importAll() {
        store.calendars(for: EKEntityType.event).forEach { c in self.importCalendar(c) }
        store.calendars(for: EKEntityType.reminder).forEach { c in self.importCalendar(c) }
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

    func importCalendar(_ cal: EKCalendar) {
        let legacy = cal.asLegacyCalendar(eventStoreId: store.eventStoreIdentifier)
        let realm = Realm.user()
        try! realm.safeWrite {
            realm.add(legacy, update: true)
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.startOfDay(for: Calendar.current.dayAfter(startOfDay))

        store.events(in: cal, from: startOfDay, to: endOfDay).forEach { self.importEvent($0, in: cal) }
        store.events(in: cal, from: longAgo(), to: startOfDay).forEach { self.importEvent($0, in: cal) }
        store.events(in: cal, from: endOfDay, to: farOffFuture()).forEach { self.importEvent($0, in: cal) }
    }

    func importEvent(_ ekEvent: EKEvent, in calendar: EKCalendar) {
        let id = ekEvent.cleanId

        if let series = Series.by(id: id) {
            importAsSeries(ekEvent, in: calendar, given: series)

        } else if let event = Event.by(id: id) {
            importAsEvent(ekEvent, in: calendar, given: event)

        } else if let reminder = Reminder.by(id: id) {
            importAsReminder(ekEvent, in: calendar, given: reminder)
        }

        if ekEvent.isRecurring && !ekEvent.isDetached {
            importAsSeries(ekEvent, in: calendar)

        } else {
            switch ekEvent.type {
            case .event:
                importAsEvent(ekEvent, in: calendar)

            case .reminder:
                importAsReminder(ekEvent, in: calendar)
            }
        }
    }

    func importAsEvent(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Event? = nil) {
        let realm = Realm.user()

        if let existing = existing {
            try! realm.safeWrite {
                existing.addParticipants(ekEvent.getParticipants())
                existing.addLink(calendar.link(to: ekEvent))
            }

        } else {
            let event = ekEvent.asEvent()
            try! realm.safeWrite {
                realm.add(event)
            }
        }
    }

    func importAsReminder(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Reminder? = nil) {
        let realm = Realm.user()

        if let existing = existing {
            try! realm.safeWrite {
                existing.addParticipants(ekEvent.getParticipants())
                existing.addLink(calendar.link(to: ekEvent))
            }

        } else {
            let reminder = ekEvent.asReminder()
            try! realm.safeWrite {
                realm.add(reminder)
            }
        }
    }

    func importAsSeries(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Series? = nil) {
        let realm = Realm.user()

        if let existing = existing {
            try! realm.safeWrite {
                existing.updateStartTimeIfEarlier(ekEvent.startDate.secondsSinceReferenceDate)
                existing.template.addParticipants(ekEvent.getParticipants())
                existing.template.addLink(calendar.link(to: ekEvent))
                existing.template.addAlarms(ekEvent.getAlarms())
            }
        } else if let rule = ekEvent.rule {
            let series = rule.asSeries(for: ekEvent, in: calendar)
            try! realm.safeWrite {
                realm.add(series)
            }
        }
    }
}
