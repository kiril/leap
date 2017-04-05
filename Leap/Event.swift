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
    dynamic var locationString: String? = nil
    dynamic var legacyTimeZone: TimeZone?
    dynamic var modalityString: String = EventModality.unknown.rawValue
    dynamic var remoteCreated: Date? = nil
    dynamic var remoteLastModified: Date? = nil
    dynamic var organizer: Person? = nil
    dynamic var agenda: Checklist? = nil
    dynamic var template: EventTemplate? = nil
    dynamic var series: Series? = nil

    let seriesEventNumber = RealmOptional<Int>()

    let channels = List<Channel>()
    let venues = List<Venue>()
    let reservations = List<Reservation>()

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }

    var date: Date? { return Date(timeIntervalSinceReferenceDate: Double(self.startTime)/1000.0) }
    var startDate: Date { return Date(timeIntervalSinceReferenceDate: Double(self.startTime)) }
    var endDate: Date { return Date(timeIntervalSinceReferenceDate: Double(self.endTime)) }

    override static func indexedProperties() -> [String] {
        return ["venue", "room", "startTime", "participants"]
    }

    var duration: TimeInterval {
        return Double(self.endTime - self.startTime)/1000.0
    }

    static func between(_ starting: Date, and before: Date) -> Results<Event> {
        let predicate = NSPredicate(format: "(startTime >= %d AND startTime < %d) OR (endTime >= %d AND endTime <= %d)", starting.secondsSinceReferenceDate, before.secondsSinceReferenceDate, starting.secondsSinceReferenceDate, before.secondsSinceReferenceDate)
        return Realm.user().objects(Event.self).filter(predicate)
        // TODO: also spanning this range??? (notes???)
    }
}
