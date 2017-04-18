//
//  Event.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import RealmSwift
import Foundation


enum EventModality: String {
    case unknown  = "unknown"
    case inPerson = "in_person"
    case video    = "video"
    case phone    = "phone"
    case chat     = "chat"
}

/**
 * Here's our core!
 */
class Event: _TemporalBase, Temporality {
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var modalityString: String = EventModality.unknown.rawValue
    dynamic var organizer: Person? = nil
    dynamic var agenda: Checklist? = nil

    let channels = List<Channel>()
    let venues = List<Venue>()
    let reservations = List<Reservation>()

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }

    var date: Date? { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }
    var startDate: Date { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }
    var endDate: Date { return Date(timeIntervalSinceReferenceDate: Double(endTime)) }
    var time: TimeInterval { return Double(startTime) }

    override static func indexedProperties() -> [String] {
        return ["venue", "room", "startTime", "endTime", "participants", "statusString"]
    }

    var duration: TimeInterval {
        return Double(self.endTime - self.startTime)
    }

    func isDuplicateOfExisting() -> Bool {
        let query = Realm.user().objects(Event.self).filter("title = %@ AND startTime = %d", title, startTime)
        return query.first != nil
    }

    static func on(_ day: GregorianDay) -> Results<Event> {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        return between(start, and: end)
    }

    static func between(_ starting: Date, and before: Date) -> Results<Event> {
        let predicate = NSPredicate(format: "statusString = %@ AND ((startTime >= %d AND startTime < %d) OR (endTime >= %d AND endTime <= %d))", ObjectStatus.active.rawValue, starting.secondsSinceReferenceDate, before.secondsSinceReferenceDate, starting.secondsSinceReferenceDate, before.secondsSinceReferenceDate)
        return Realm.user().objects(Event.self).filter(predicate).sorted(byKeyPath: "startTime")
        // TODO: also spanning this range??? (notes???)
    }
}
