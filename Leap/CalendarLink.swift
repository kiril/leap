//
//  CalendarLink.swift
//  Leap
//
//  Created by Kiril Savino on 4/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


class CalendarLink: Object {
    dynamic var calendar: LegacyCalendar?
    dynamic var itemId: String = ""
    dynamic var externalItemId: String?

    override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? CalendarLink {
            let lhs = self
            return lhs.calendar == rhs.calendar && lhs.itemId == rhs.itemId && lhs.externalItemId == rhs.externalItemId
        }
        return false
    }
}
