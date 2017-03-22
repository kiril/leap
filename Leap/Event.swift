//
//  Event.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import RealmSwift
import Foundation

enum EventRelationship: String {
    case invitee     = "invitee"
    case creator     = "creator"
    case participant = "participant"
    case observer    = "observer"
}

class Event: LeapModel {
    dynamic var startTime: Date = Date()
    dynamic var endTime: Date = Date()
    dynamic var calendar: LegacyCalendar? = nil
    dynamic var relationshipString = EventRelationship.creator.rawValue

    var relationship: EventRelationship {
        get { return EventRelationship(rawValue: relationshipString)! }
        set { relationshipString = newValue.rawValue }
    }
}
