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


func syncEventSearchCallback(for calendar: LegacyCalendar) -> EKEventSearchCallback {
    let calendarId = calendar.id
    func sync(ekEvent: EKEvent, stopBoolPointer: UnsafeMutablePointer<ObjCBool>) {
        let realm = Realm.user()
        let calendar = LegacyCalendar.by(id: calendarId)! // deliberate re-fetch cuz threads
        let temporality = ekEvent.asTemporality()

        try! realm.write {
            switch temporality {
            case var event as Event:
                let existing = Event.by(id: event.id)

                if let existing = existing {

                    if event.isUpdatedVersionOf(existing) {
                        // keep any calendar links we might have
                        for link in existing.links {
                            event.linkTo(link: link)
                        }
                        // TODO: actually figure out change sets
                    } else {
                        event = existing
                    }
                } else if event.isDuplicateOfExisting() {
                    // TODO: should I record this somehow? is it a calendar thing?
                    print("DUPLICATE \(event.title)")
                    break
                }

                event.linkTo(calendar: calendar,
                             itemId: ekEvent.calendarItemIdentifier,
                             externalItemId: ekEvent.calendarItemExternalIdentifier)

                if existing == nil {
                    print(" + Event \(event.title)")
                }
                realm.add(event, update: true)

            case var reminder as Reminder:
                let existing = Reminder.by(id: reminder.id)
                if let existing = existing {
                    if reminder.isUpdatedVersionOf(existing) {
                        for link in existing.links {
                            reminder.linkTo(link: link)
                        }
                    } else {
                        reminder = existing
                    }
                } else if reminder.isDuplicateOfExisting() {
                    // TODO: should I record this somehow? is it a calendar thing?
                    print("DUPLICATE \(reminder.title)")
                    break
                }


                reminder.linkTo(calendar: calendar,
                                itemId: ekEvent.calendarItemIdentifier,
                                externalItemId: ekEvent.calendarItemExternalIdentifier)
                if existing == nil {
                    print(" + Reminder \(reminder.title)")
                }
                realm.add(reminder, update: true)
            default:
                return
            }
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
    func syncThisWeekEvents(forCalendar calendar: LegacyCalendar) -> Bool {
        guard let ekCalendar = calendar.asEKCalendar(eventStore: self) else {
            print("Failed to sync past events for a calendar")
            return false
        }

        let startOfToday = Calendar.current.startOfDay(for: Calendar.current.today)
        let endOfToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!

        let minus7days = DateComponents(calendar: Calendar.current, day: -7)
        let plus7days = DateComponents(calendar: Calendar.current, day: 7)

        let startOfWeek = Calendar.current.date(byAdding: minus7days, to: startOfToday, wrappingComponents: true)!
        let endOfWeek = Calendar.current.date(byAdding: plus7days, to: endOfToday, wrappingComponents: true)!

        let predicate: NSPredicate = predicateForEvents(withStart: startOfWeek,
                                                        end: endOfWeek,
                                                        calendars: [ekCalendar])


        self.enumerateEvents(matching: predicate, using: syncEventSearchCallback(for: calendar))
        return true
    }

    @discardableResult
    func syncDayEvents(forCalendar calendar: LegacyCalendar, withDayOffset offset: Int) -> Bool {
        guard let ekCalendar = calendar.asEKCalendar(eventStore: self) else {
            print("Failed to sync past events for a calendar")
            return false
        }

        let startOfToday = Calendar.current.startOfDay(for: Calendar.current.today)
        let endOfToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!

        let offset = DateComponents(calendar: Calendar.current, day: offset)

        let startOfDay = Calendar.current.date(byAdding: offset, to: startOfToday, wrappingComponents: true)!
        let endOfDay = Calendar.current.date(byAdding: offset, to: endOfToday, wrappingComponents: true)!

        let predicate: NSPredicate = predicateForEvents(withStart: startOfDay,
                                                        end: endOfDay,
                                                        calendars: [ekCalendar])


        self.enumerateEvents(matching: predicate, using: syncEventSearchCallback(for: calendar))
        return true
    }

    @discardableResult
    func syncTodayEvents(forCalendar calendar: LegacyCalendar) -> Bool {
        guard let ekCalendar = calendar.asEKCalendar(eventStore: self) else {
            print("Failed to sync past events for a calendar")
            return false
        }

        let startOfToday = Calendar.current.startOfDay(for: Calendar.current.today)
        let endOfToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!

        let predicate: NSPredicate = predicateForEvents(withStart: startOfToday,
                                                        end: endOfToday,
                                                        calendars: [ekCalendar])


        self.enumerateEvents(matching: predicate, using: syncEventSearchCallback(for: calendar))
        return true
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
