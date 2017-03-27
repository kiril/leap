//
//  Temporality.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


/**
 * How is this even on my radar?
 */
enum Ownership: String {
    case invitee     = "invitee" // I got invited to it
    case creator     = "creator" // I created it
    case participant = "participant" // I'm participating / attending / RSVP'ed
    case observer    = "observer" // It's been shared with me in some passive way
    case none        = "none" // I have no relationship: useful, though unlikely to be stored anywhere
}


/**
 * What is my intention regarding this event? Am I "going" (engaged, as in engagement),
 * am I skipping it (disengaged), or something in between
 */
enum Engagement: String {
    case undecided   = "undecided" // hasn't dealt with it
    case tracking    = "tracking" // maybe/ignored / in the background
    case engaged     = "engaged" // attending / committed
    case disengaged  = "disengaged" // declined / deleted
    case none        = "none" // as above, a neutral status that is unlikely to be stored but useful for completeness
}


protocol Temporality {
    var externalId: String? { get }
    var date: Date? { get }
    var isRecurring: Bool { get }
    var userEngagement: Engagement { get set }
    var userOwnership: Ownership { get set }
    var recurrence: Recurrence? { get set }
    var participants: List<Participant> { get }
    var me: Participant? { get }
    var externalURL: String? { get set }
    var alarms: List<Alarm> { get }
    var duration: TimeInterval { get }
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
}

class _TemporalBase: LeapModel {
    dynamic var externalId: String? = nil
    dynamic var title: String = ""
    dynamic var detail: String = ""
    dynamic var recurrence: Recurrence?
    dynamic var userOwnershipString = Ownership.creator.rawValue // right default?
    dynamic var userEngagementString = Engagement.undecided.rawValue
    dynamic var externalURL: String?
    let alarms = List<Alarm>()
    let participants = List<Participant>()
    let sourceCalendars = List<LegacyCalendar>()

    var isRecurring: Bool { return recurrence != nil }

    var userOwnership: Ownership {
        get { return Ownership(rawValue: userOwnershipString)! }
        set { userOwnershipString = newValue.rawValue }
    }

    var userEngagement: Engagement {
        get { return Engagement(rawValue: userEngagementString)! }
        set { userEngagementString = newValue.rawValue }
    }
}
