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
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.startOfDay(for: Calendar.current.dayAfter(startOfDay))
        // get today's stuff flowing in fast
        store.calendars(for: EKEntityType.event).forEach { c in self.importEvents(in: c, from: startOfDay, to: endOfDay) }
        store.calendars(for: EKEntityType.reminder).forEach { c in self.importEvents(in: c, from: startOfDay, to: endOfDay) }

        // future, because you're more likely to look there soon
        store.calendars(for: EKEntityType.event).forEach { c in self.importEvents(in: c, from: endOfDay, to: farOffFuture()) }
        store.calendars(for: EKEntityType.reminder).forEach { c in self.importEvents(in: c, from: endOfDay, to: farOffFuture()) }

        // then get the past (which cleans up some stuff about event recurrence, too)
        store.calendars(for: EKEntityType.event).forEach { c in self.importEvents(in: c, from: longAgo(), to: startOfDay) }
        store.calendars(for: EKEntityType.reminder).forEach { c in self.importEvents(in: c, from: longAgo(), to: startOfDay) }
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
        if let series = Series.by(id: ekEvent.cleanId) { // always keep series as series, even if arrives w/o recurrence info
            importAsSeries(ekEvent, in: calendar, given: series)

        } else {

            if ekEvent.isRecurring && !ekEvent.isDetached {
                importAsSeries(ekEvent, in: calendar, given: Series.by(id: ekEvent.cleanId))

            } else {
                switch ekEvent.type {
                case .event:
                    importAsEvent(ekEvent, in: calendar, given: Event.by(id: ekEvent.cleanId))

                case .reminder:
                    if let series = Series.by(title: ekEvent.title),
                        (series.isExactRecurrence(date: ekEvent.startDate) || (ekEvent.isAllDay && series.recurrence.recursOn(ekEvent.startDate, for: series))) {
                        print("reminder DUPLICATE of Series \(ekEvent.title)")
                        importAsSeries(ekEvent, in: calendar, given: series)

                    } else {
                        importAsReminder(ekEvent, in: calendar, given: Reminder.by(id: ekEvent.cleanId))
                    }
                }
            }
        }
    }

    func importAsEvent(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Event? = nil) {
        let realm = Realm.user()

        if let existing = existing {
            if existing.participants.isEmpty && ekEvent.hasAttendees {
                try! realm.safeWrite {
                    existing.addParticipants(ekEvent.getParticipants())
                }
                if let me = existing.me, me.engagement == .disengaged, existing.status != .archived {
                    try! realm.safeWrite {
                        existing.status = .archived
                    }
                }
            }
            try! realm.safeWrite {
                existing.addLink(to: calendar)
            }
            print("event UPDATE \(ekEvent.title)")

        } else {
            let event = ekEvent.asEvent(in: calendar)
            if let me = event.me, me.engagement == .disengaged {
                event.status = .archived
            }
            event.insert()
            print("event INSERT \(ekEvent.title)")
        }
    }

    func importAsReminder(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Reminder? = nil) {
        let realm = Realm.user()

        if let existing = existing {
            if existing.participants.isEmpty && ekEvent.hasAttendees {
                try! realm.safeWrite {
                    existing.addParticipants(ekEvent.getParticipants())
                }
            }
            try! realm.safeWrite {
                existing.addLink(to: calendar)
            }
            print("reminder UPDATE \(ekEvent.title)")

        } else {
            let reminder = ekEvent.asReminder(in: calendar)
            reminder.insert()
            print("reminder INSERT \(ekEvent.title)")
        }
    }

    func importAsSeries(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Series? = nil) {
        if let event = Event.by(id: ekEvent.cleanId) {
            event.delete()
            print("event DELETE series root \(ekEvent.title)")
        }
        if let reminder = Reminder.by(id: ekEvent.cleanId) {
            reminder.delete()
            print("reminder DELETE series root \(ekEvent.title)")
        }

        if let existing = existing {
            guard ekEvent.startDate < existing.startDate else {
                return
            }

            try! Realm.user().safeWrite {
                existing.updateStartTimeIfEarlier(ekEvent.startDate.secondsSinceReferenceDate)
                existing.template.addParticipants(ekEvent.getParticipants())
                existing.template.addLink(to: calendar)
                existing.template.addAlarms(ekEvent.getAlarms())
                if let me = existing.template.me, me.engagement == .disengaged, existing.status != .archived {
                    existing.status = .archived
                }
            }
            print("series UPDATE \(ekEvent.title)")

        } else if let rule = ekEvent.rule {
            let series = rule.asSeries(for: ekEvent, in: calendar)
            if let me = series.template.me, me.engagement == .disengaged {
                series.status = .archived
            }
            series.insert()
            print("series INSERT \(ekEvent.title)")
        }
    }
}
