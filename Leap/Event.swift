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
    dynamic var startTime: Date?
    dynamic var endTime: Date?
    dynamic var locationString: String?
    dynamic var legacyTimeZone: TimeZone?
    dynamic var modalityString: String = EventModality.unknown.rawValue
    dynamic var remoteCreated: Date?
    dynamic var remoteLastModified: Date?
    dynamic var organizer: Person?

    let channels = List<Channel>()
    let venues = List<Venue>()
    let rooms = List<Room>()
    let resources = List<Resource>()

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }

    var date: Date? { return self.startTime }

    override static func indexedProperties() -> [String] {
        return ["venue", "room", "startTime", "participants"]
    }
}
