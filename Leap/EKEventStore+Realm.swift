//
//  EKEventStore+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit
import RealmSwift

func mergeTemporalities<T:Temporality>(existing: T?, new: T) -> T {
    // ok, so... how do I update events this way??
    // * check if this has been modified more recently than what I have
    // * if it hasn't, just make sure this calendar is linked
    // * if it has, both update this event, and make sure the calendar is linked
    // * FUTURE: be much smarter about what changed when. :(
    //   this _is_ the argument for keeping an OpLog even here, isn't it...
    guard let existing = existing else {
        return new
    }

    var hasChanged = false
    let existingLastModified = existing.remoteLastModified
    let newLastModified = new.remoteLastModified
    if newLastModified != nil, existingLastModified == nil {
        hasChanged = true
    } else if let elm = existingLastModified,
        let nlm = newLastModified,
        Calendar.current.isDate(nlm, after: elm) {
        hasChanged = true
    }

    if hasChanged {
        // copy over the links from the old event
        for link in existing.links {
            new.linkTo(link: link)
        }
        return new

    } else {
        return existing // just use the old event
    }
}

func syncEventSearchCallback(for calendar: LegacyCalendar) -> EKEventSearchCallback {
    let calendarId = calendar.id
    func sync(ekEvent: EKEvent, stopBoolPointer: UnsafeMutablePointer<ObjCBool>) {
        let realm = Realm.user()
        let calendar = LegacyCalendar.by(id: calendarId)! // deliberate re-fetch cuz threads
        let temporality = ekEvent.asTemporality()

        switch temporality {
        case var event as Event:
            event = mergeTemporalities(existing: Event.by(id: event.id), new: event)

            event.linkTo(calendar: calendar,
                         itemId: ekEvent.calendarItemIdentifier,
                         externalItemId: ekEvent.calendarItemExternalIdentifier)
            try! realm.write {
                print(" + Event \(event.title) @ \(calendar.title)")
                realm.add(event, update: true)

            }
        case var reminder as Reminder:
            reminder = mergeTemporalities(existing: Reminder.by(id: reminder.id), new: reminder)

            reminder.linkTo(calendar: calendar,
                            itemId: ekEvent.calendarItemIdentifier,
                            externalItemId: ekEvent.calendarItemExternalIdentifier)
            try! realm.write {
                print(" + Reminder \(reminder.title) @ \(calendar.title)")
                realm.add(reminder, update: true)
            }   
        default:
            return
        }
    }
    return sync
}

extension EKEventStore {

    func legacyCalendars() -> [LegacyCalendar] {
        let eventCalendars = self.calendars(for: EKEntityType.event)
        let reminderCalendars = self.calendars(for: EKEntityType.reminder)

        return eventCalendars.map { $0.asLegacyCalendar(eventStoreId: self.eventStoreIdentifier) } + reminderCalendars.map { $0.asLegacyCalendar(eventStoreId: self.eventStoreIdentifier) }
    }

    @discardableResult
    func syncPastEvents(forCalendar calendar: LegacyCalendar) -> Bool {
        guard let ekCalendar = calendar.asEKCalendar(eventStore: self) else {
            print("Failed to sync past events for a calendar")
            return false
        }

        let endOfToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let minus4years = DateComponents(calendar: Calendar.current, year: -4)
        let aLongTimeAgo = Calendar.current.date(byAdding: minus4years, to: endOfToday, wrappingComponents: true)!

        let predicate: NSPredicate = predicateForEvents(withStart: aLongTimeAgo,
                                                        end: endOfToday,
                                                        calendars: [ekCalendar])


        self.enumerateEvents(matching: predicate, using: syncEventSearchCallback(for: calendar))
        return true
    }

    @discardableResult
    func syncFutureEvents(forCalendar calendar: LegacyCalendar) -> Bool {
        guard let ekCalendar = calendar.asEKCalendar(eventStore: self) else {
            print("Failed to sync past events for a calefndar")
            return false
        }

        let startOfToday = Calendar.current.startOfDay(for: Calendar.current.today)
        let plus4years = DateComponents(calendar: Calendar.current, year: 4)
        let farFuture = Calendar.current.date(byAdding: plus4years, to: startOfToday, wrappingComponents: true)!

        let predicate: NSPredicate = predicateForEvents(withStart: startOfToday,
                                                        end: farFuture,
                                                        calendars: [ekCalendar])

        self.enumerateEvents(matching: predicate, using: syncEventSearchCallback(for: calendar))
        return true
    }

    // because there's something wonky about shared calendars and the normal
    // EKEventStore.calendar(withIdentifier:) function (see: The Internet, error 1014)
    func findCalendarGently(withIdentifier id: String) -> EKCalendar? {
        let eventCalendars = self.calendars(for: EKEntityType.event)
        for calendar in eventCalendars {
            if calendar.calendarIdentifier == id {
                return calendar
            }
        }
        let reminderCalendars = self.calendars(for: EKEntityType.reminder)
        for calendar in reminderCalendars {
            if calendar.calendarIdentifier == id {
                return calendar
            }
        }
        fatalError("Couldn't find calendar \(id) anywhere!!!")
    }
}
