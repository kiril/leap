//
//  Realm+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {

    // Events
    func event(byId id: String) -> Event? {
        return objects(Event.self).filter("id = '\(id)'").first
    }

    func events(startingOnOrAfter after: Date,
                butBefore before: Date) -> Results<Event> {
        let predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", after as NSDate, before as NSDate)
        return objects(Event.self).filter(predicate)
    }

    // Reminders

    func reminder(byId id: String) -> Reminder? {
        return objects(Reminder.self).filter("id = '\(id)'").first
    }

    func reminders(startingOnOrAfter after: Date,
                   butBefore before: Date) -> Results<Reminder> {
        let predicate = NSPredicate(format: "startDate >= %@ AND startDate < %@", after as NSDate, before as NSDate)
        return objects(Reminder.self).filter(predicate).sorted(byKeyPath: "startDate")
    }

    // People

    func me() -> Person? {
        return objects(Person.self).filter("isMe = true").first
    }

    func person(byId id: String) -> Person? {
        return objects(Person.self).filter("id = '\(id)'").first
    }

    func person(byEmail email: String) -> Person? {
        return objects(Person.self).filter("email = '\(email)'").first
    }

    func venue(byId id: String) -> Venue? {
        return objects(Venue.self).filter("id = '\(id)'").first
    }
}
