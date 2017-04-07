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
    var wasDetached: Bool { get }
    var participants: List<Participant> { get }
    var me: Participant? { get }
    var externalURL: String? { get set }
    var alarms: List<Alarm> { get }
    var duration: TimeInterval { get }
    var links: List<CalendarLink> { get }
    var remoteCreated: Date? { get }
    var remoteLastModified: Date? { get }
    var series: Series? { get }
    var seriesEventNumber: RealmOptional<Int> { get }

    func isUpdatedVersionOf(_ other: Temporality) -> Bool
    func isDuplicateOfExisting() -> Bool
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

    func isUpdatedVersionOf(_ old: Temporality) -> Bool {

        // for recurring events, we want the earliest instance
        if old.isRecurring, !wasDetached {
            if Calendar.current.isDate(self.date!, after: old.date!) {
                return false // this is just a new instance of the same old one
            } else if Calendar.current.isDate(self.date!, before: old.date!) {
                return true // the new one is in fact earlier and should override as the actual original
            }
        }

        // now let's figure out if we just don't have a change
        var hasChanged = false
        let oldLastModified = old.remoteLastModified
        let newLastModified = remoteLastModified
        if newLastModified != nil, oldLastModified == nil {
            hasChanged = true
        } else if let olm = oldLastModified,
            let nlm = newLastModified,
            Calendar.current.isDate(nlm, after: olm) {
            hasChanged = true
        }

        if hasChanged {
            return true // cool, this is an updated version

        } else {
            return false // just use the old one
        }
    }
}

class _TemporalBase: LeapModel {
    dynamic var externalId: String? = nil
    dynamic var title: String = ""
    dynamic var detail: String? = nil
    dynamic var externalURL: String?
    dynamic var remoteCreated: Date? = nil
    dynamic var remoteLastModified: Date? = nil
    dynamic var series: Series? = nil
    dynamic var wasDetached: Bool = false

    let seriesEventNumber = RealmOptional<Int>()

    let alarms = List<Alarm>()
    let participants = List<Participant>()
    let sourceCalendars = List<LegacyCalendar>()
    let links = List<CalendarLink>()

    var isRecurring: Bool { return series != nil }
}


class CalendarLink: Object {
    dynamic var calendar: LegacyCalendar?
    dynamic var itemId: String = ""
    dynamic var externalItemId: String?
}
