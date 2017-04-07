//
//  Temporality.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift



protocol Temporality {
    var externalId: String? { get }
    var date: Date? { get }
    var isRecurring: Bool { get }
    var recurrence: Recurrence? { get set }
    var participants: List<Participant> { get }
    var me: Participant? { get }
    var externalURL: String? { get set }
    var alarms: List<Alarm> { get }
    var duration: TimeInterval { get }
    var links: List<CalendarLink> { get }
    var remoteCreated: Date? { get }
    var remoteLastModified: Date? { get }
}

extension Temporality {
    var me: Participant? {
        for participant in participants {
            if let person = participant.person, person.isMe {
                return participant
            }
        }

        return nil
    }

    func linkTo(calendar: LegacyCalendar, itemId: String, externalItemId: String?) {
        for link in links {
            if link.calendar == calendar {
                return
            }
        }
        links.append(CalendarLink(value: ["itemId": itemId as Any?,
                                          "externalItemId": externalItemId,
                                          "calendar": calendar as Any?]))
    }

    func linkTo(link newLink: CalendarLink) {
        for link in links {
            if link.calendar == newLink.calendar {
                return
            }
        }
        links.append(newLink)
    }
}

class _TemporalBase: LeapModel {
    dynamic var externalId: String? = nil
    dynamic var title: String = ""
    dynamic var detail: String? = nil
    dynamic var recurrence: Recurrence?
    dynamic var externalURL: String?
    dynamic var remoteCreated: Date? = nil
    dynamic var remoteLastModified: Date? = nil
    let alarms = List<Alarm>()
    let participants = List<Participant>()
    let sourceCalendars = List<LegacyCalendar>()
    let links = List<CalendarLink>()

    var isRecurring: Bool { return recurrence != nil }
}


class CalendarLink: Object {
    dynamic var calendar: LegacyCalendar?
    dynamic var itemId: String = ""
    dynamic var externalItemId: String?
}
