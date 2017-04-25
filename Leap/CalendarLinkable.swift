//
//  Linkable.swift
//  Leap
//
//  Created by Kiril Savino on 4/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift
import EventKit

protocol CalendarLinkable {
    var linkedCalendarIds: List<StringObject> { get }
}

extension CalendarLinkable {
    func addLink(to linkable: CalendarLinkIdentifiable) {
        addLink(to: linkable.calendarLinkId)
    }

    func addLink(to string: String) {
        let id = StringObject(string)

        if !linkedCalendarIds.contains(id) {
            linkedCalendarIds.append(id)
        }
    }
    var linkedCalendars: [LegacyCalendar] {
        return linkedCalendarIds.flatMap { LegacyCalendar.by(id: $0.stringValue) }
    }
}

protocol CalendarLinkIdentifiable {
    var calendarLinkId: String { get }
}

extension CalendarLinkIdentifiable {
    func asLinkId() -> StringObject {
        return StringObject(calendarLinkId)
    }
}

class StringObject: Object {
    // move this somewhere else if useful?
    public dynamic var stringValue = ""

    convenience init(_ string: String) {
        self.init(value: ["stringValue": string])
    }

    override func isEqual(_ object: Any?) -> Bool {
        if  let rhs = object as? StringObject {
            let lhs = self
            return lhs.stringValue == rhs.stringValue
        }
        return false
    }
}

extension LegacyCalendar: CalendarLinkIdentifiable {
    var calendarLinkId: String { return id }
}
extension EKCalendar: CalendarLinkIdentifiable {
    var calendarLinkId: String { return calendarIdentifier }
}
