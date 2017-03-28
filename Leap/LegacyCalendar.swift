//
//  LegacyCalendar.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum CalendarRelationship: String {
    case owner      = "owner"
    case follower   = "follower"
}

class LegacyCalendar: LeapModel {
    dynamic var userId: String = ""
    dynamic var eventStoreId: String = ""
    dynamic var writable: Bool = false
    dynamic var editable: Bool = false
    dynamic var relationshipString: String = CalendarRelationship.owner.rawValue
    var relationship: CalendarRelationship {
        get { return CalendarRelationship(rawValue: relationshipString)! }
        set { relationshipString = newValue.rawValue }
    }
    dynamic var color: String = "#000000"

    override static func indexedProperties() -> [String] {
        return ["userId", "remoteId"]
    }

    dynamic var account: DeviceAccount?

    static func by(id: String) -> LegacyCalendar? {
        return fetch(id: id)
    }
}
