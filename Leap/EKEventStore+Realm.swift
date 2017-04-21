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
                var existing = Event.by(id: event.id)
                if let e = existing, e === event {
                    existing = nil
                }

                if let existing = existing {

                    if event.isBetterVersionOf(existing) {
                        // keep any calendar links we might have, but overwrite with this
                        let series = event.seriesId != nil ? Series.by(id: event.seriesId!) : nil
                        for link in existing.links {
                            event.linkTo(link: link)
                            if let series = series, !series.links.contains(link) {
                                try! Realm.user().safeWrite {
                                    series.links.append(link)
                                }
                            }
                        }
                        if existing.isRecurring && !event.isRecurring {
                            event.seriesId = existing.seriesId
                            event.status = .archived
                        }
                        if let oldMe = existing.me, let newMe = event.me {
                            if oldMe.engagement == .engaged && newMe.engagement == .undecided {
                                newMe.engagement = .engaged // horrible hack
                            }
                        } else if !existing.participants.isEmpty && event.participants.isEmpty {
                            event.participants.append(objectsIn: existing.participants) // horrible hack
                            event.finagleParticipantStatus()
                        }
                        // TODO: actually figure out change sets
                    } else {
                        let series = existing.seriesId != nil ? Series.by(id: existing.seriesId!) : nil

                        for link in event.links {
                            if let series = series, !series.links.contains(link) {
                                try! Realm.user().safeWrite {
                                    series.links.append(link)
                                }
                            }
                        }
                        if event.isRecurring && !existing.isRecurring {
                            existing.seriesId = event.seriesId
                            existing.status = .archived
                        }
                        if !existing.wasDetached && !event.wasDetached {
                            if let oldMe = existing.me, let newMe = event.me {
                                if newMe.engagement == .engaged && oldMe.engagement == .undecided {
                                    oldMe.engagement = .engaged // horrible hack
                                }
                            } else if !event.participants.isEmpty && existing.participants.isEmpty {
                                existing.participants.append(objectsIn: event.participants) // horrible hack
                                existing.finagleParticipantStatus()
                            }
                            event = existing
                        }
                    }
                } else if event.isDuplicateOfExisting() {
                    // TODO: should I record this somehow? is it a calendar thing?
                    print("DUPLICATE \(event.title)")
                    break
                }

                event.linkTo(calendar: calendar,
                             itemId: ekEvent.calendarItemIdentifier,
                             externalItemId: ekEvent.calendarItemExternalIdentifier)
                if calendar.relationship == .owner && event.origin == .share {
                    event.origin = .personal
                    if event.participants.isEmpty {
                        let me = Person.me() ?? Person(value: ["isMe": true])
                        let participant = Participant(value: ["person": me,
                                                              "engagementString": Engagement.engaged.rawValue,
                                                              "ownershipString": Ownership.organizer.rawValue,
                                                              "importanceString": ParticipationImportance.critical.rawValue])
                        event.participants.append(participant)
                    }
                }

                if let seriesId = event.seriesId, let series = Series.by(id: seriesId) {
                    for link in event.links {
                        if !series.links.contains(link) {
                            series.links.append(link)
                        }
                    }
                }

                if existing == nil {
                    print(" + \(event.title) via \(calendar.title) [\(event.statusString)]")
                }
                realm.add(event, update: true)

            case var reminder as Reminder:
                let existing = Reminder.by(id: reminder.id)
                if let existing = existing {
                    if reminder.isBetterVersionOf(existing) {
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
                    print(" R \(reminder.title)")
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
