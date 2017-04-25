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
    var linkedCalendarIds: List<StringWrapper> { get }
}

extension CalendarLinkable {
    func addLink(to linkable: CalendarLinkIdentifiable) {
        addLink(to: linkable.calendarLinkId)
    }

    func addLink(to string: String) {
        let id = StringWrapper(string)

        if !linkedCalendarIds.contains(id) {
            linkedCalendarIds.append(id)
        }
    }

    var linkedCalendars: [LegacyCalendar] {
        return linkedCalendarIds.flatMap { LegacyCalendar.by(id: $0.raw) }
    }
}

protocol CalendarLinkIdentifiable {
    var calendarLinkId: String { get }
}

extension CalendarLinkIdentifiable {
    func asLinkId() -> StringWrapper {
        return StringWrapper(calendarLinkId)
    }
}

extension LegacyCalendar: CalendarLinkIdentifiable {
    var calendarLinkId: String { return id }
}
extension EKCalendar: CalendarLinkIdentifiable {
    var calendarLinkId: String { return calendarIdentifier }
}
