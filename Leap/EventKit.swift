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

                if ekEvent.isRecurring && !ekEvent.isDetached {
                    let existing = Series.by(id: ekEvent.cleanId)
                    self.importAsSeries(ekEvent, in: calendar, given: existing)

                } else {
                    switch ekEvent.type {
                    case .event:
                        let existing = Event.by(id: ekEvent.cleanId)
                        self.importAsEvent(ekEvent, in: calendar, given: existing)

                    case .reminder:
                        if let series = Series.by(title: ekEvent.title),
                            (series.isExactRecurrence(date: ekEvent.startDate) || (ekEvent.isAllDay && series.recurrence.recursOn(ekEvent.startDate, for: series))) {
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

    func merge(_ ekEvent: EKEvent, into another: Temporality, in calendar: EKCalendar) {
        var existing = another
        let realm = Realm.user()
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
        if let linkable = existing as? CalendarLinkable {
            try! realm.safeWrite {
                linkable.addLink(to: calendar)
            }
        }
        print("\(type(of:existing)) UPDATE \(ekEvent.title)")
    }

    func importAsEvent(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Event? = nil) {
        if let existing = existing {
            merge(ekEvent, into: existing, in: calendar)

        } else {
            let event = ekEvent.asEvent(in: calendar)
            if let duplicate = Event.by(fuzzyHash: event.calculateFuzzyHash()) {
                print("event DUPLICATE \(ekEvent.title)")
                merge(ekEvent, into: duplicate, in: calendar)

            } else {
                if let me = event.me, me.engagement == .disengaged {
                    event.status = .archived
                }
                event.insert()
                print("event INSERT \(ekEvent.title) from \(calendar.title)")
                if ekEvent.title.contains("Eleni") {
                    print("    Calendar: \(calendar.title) - \(calendar.calendarIdentifier)")
                    print("    Source: \(calendar.source.title) - \(calendar.source.sourceIdentifier)")
                    print("    ID: \(ekEvent.eventIdentifier)")
                }
            }
        }
    }

    func importAsReminder(_ ekEvent: EKEvent, in calendar: EKCalendar, given existing: Reminder? = nil) {
        if let existing = existing {
            merge(ekEvent, into: existing, in: calendar)

        } else {
            let reminder = ekEvent.asReminder(in: calendar)
            if let duplicate = Reminder.by(fuzzyHash: reminder.calculateFuzzyHash()) {
                print("reminder DUPLICATE \(ekEvent.title)")
                merge(ekEvent, into: duplicate, in: calendar)
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
            existing.template.addParticipants(ekEvent.getParticipants())
            existing.template.addLink(to: calendar)
            existing.template.addAlarms(ekEvent.getAlarms())
            if let me = existing.template.me, me.engagement == .disengaged, existing.status != .archived {
                existing.status = .archived
            }
        }
        print("series UPDATE \(ekEvent.title)")
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
            merge(ekEvent, into: existing, in: calendar)

        } else if let rule = ekEvent.rule {
            let series = rule.asSeries(for: ekEvent, in: calendar)
            if let duplicate = Series.by(fuzzyHash: series.calculateFuzzyHash()) {
                print("series DUPLICATE \(duplicate.title)")
                merge(ekEvent, into: duplicate, in: calendar)
            } else {
                if let me = series.template.me, me.engagement == .disengaged {
                    series.status = .archived
                }
                series.insert()
                print("series INSERT \(ekEvent.title)")
            }
        }
    }
}
