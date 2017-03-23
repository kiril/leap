//
//  EKEventStore+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

func syncEventSearchCallback(for calendar: LegacyCalendar) -> EKEventSearchCallback {
    func sync(ekEvent: EKEvent, stopBoolPointer: UnsafeMutablePointer<ObjCBool>) {
        let temporality = ekEvent.asTemporality()
        switch temporality {
        case let event as Event:
            calendar.sync(event: event)
        case let reminder as Reminder:
            calendar.sync(reminder: reminder)
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

    func syncPastEvents(forCalendar calendar: LegacyCalendar) -> Bool {
        guard let ekCalendar = calendar.asEKCalendar() else {
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

    func syncFutureEvents(forCalendar calendar: LegacyCalendar) -> Bool {
        guard let ekCalendar = calendar.asEKCalendar() else {
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
}
