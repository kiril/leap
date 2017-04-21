//
//  Temporality.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift
import EventKit


enum Origin: String {
    case invite
    case share
    case subscription
    case personal
    case unknown
}


protocol Temporality {
    var id: String { get }
    var title: String { get }
    var detail: String? { get }
    var externalId: String? { get }
    var origin: Origin { get set }

    var date: Date? { get }
    var time: TimeInterval { get }
    var duration: TimeInterval { get }

    var locationString: String? { get }
    var legacyTimeZone: TimeZone? { get }
    var remoteCreated: Date? { get }
    var remoteLastModified: Date? { get }

    var isRecurring: Bool { get }
    var wasDetached: Bool { get }

    var participants: List<Participant> { get }
    var me: Participant? { get }

    var externalURL: String? { get set }
    var alarms: List<Alarm> { get }
    var links: List<CalendarLink> { get }

    var seriesId: String? { get set }
    var seriesEventNumber: RealmOptional<Int> { get }
    var template: Template? { get set }

    func isBetterVersionOf(_ other: Temporality) -> Bool
    func isDuplicateOfExisting() -> Bool

    var status: ObjectStatus { get set }
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

    var organizer: Participant? {
        for participant in participants {
            if participant.ownership == .organizer {
                return participant
            }
        }

        return nil
    }

    var invitees: [Participant] {
        var them: [Participant] = []
        for participant in participants {
            if participant.person != nil && participant.ownership != .organizer {
                them.append(participant)
            }
        }
        return them
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

    func isBetterVersionOf(_ old: Temporality) -> Bool {

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
    dynamic var seriesId: String? = nil
    dynamic var wasDetached: Bool = false
    dynamic var locationString: String? = nil
    dynamic var legacyTimeZone: TimeZone?
    dynamic var template: Template?
    dynamic var originString: String = Origin.unknown.rawValue

    let seriesEventNumber = RealmOptional<Int>()

    let alarms = List<Alarm>()
    let participants = List<Participant>()
    let links = List<CalendarLink>()

    var isRecurring: Bool { return seriesId != nil }

    var origin: Origin {
        get { return Origin(rawValue: originString)! }
        set { originString = newValue.rawValue }
    }
}


extension Temporality {

    func finagleParticipantStatus(availability: EKEventAvailability = .busy) {
        if participants.count == 1 && participants[0].isMe {
            switch availability {
            case .busy, .unavailable, .notSupported:
                participants[0].engagement = .engaged
            default:
                participants[0].engagement = .tracking
            }
        }

        if let me = self.me, me.ownership == .organizer && me.engagement == .undecided {
            me.engagement = .engaged // fuck me, Google, you suck via EventKit, ok?
        }
    }
}


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
