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
    dynamic var startTime: Date? = nil
    dynamic var endTime: Date? = nil
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

    var date: Date? { return self.startTime }

    override static func indexedProperties() -> [String] {
        return ["venue", "room", "startTime", "participants"]
    }

    var duration: TimeInterval {
        guard let end = endTime, let start = startTime else {
            return 0.0
        }
        return end.timeIntervalSince(start)
    }
}
