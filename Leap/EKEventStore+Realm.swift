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


extension EKEventStore {
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

    func events(in calendar: EKCalendar, from start: Date, to end: Date) -> [EKEvent] {
        let predicate: NSPredicate = predicateForEvents(withStart: start, end: end, calendars: [calendar])
        return events(matching: predicate)
    }

    func enumerateEvents(in calendar: EKCalendar, from start: Date, to end: Date, using callback: @escaping EKEventSearchCallback) {
        enumerateEvents(matching: predicateForEvents(withStart: start, end: end, calendars: [calendar]), using: callback)
    }
}
