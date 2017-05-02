//
//  Participant.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift



/**
 * How is this even on my radar?
 */
enum Ownership: String {
    case unknown     = "unknown"
    case invitee     = "invitee" // I got invited to it
    case organizer   = "organizer" // I created it
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


enum Participation: String {
    case unknown  = "unknown"
    case attendee = "attendee"
    case observer = "observer"
    case none     = "none"
}


enum ParticipationImportance: String {
    case unknown  = "unknown"
    case optional = "optional"
    case valued   = "valued"
    case critical = "critical"
}


enum ParticipationType: String {
    case unknown      = "unknown"
    case inPerson     = "in_person"
    case remote       = "remote"
    case delegating   = "delegating"
    case asynchronous = "asynchronous"
    case informed     = "informed"
}


class Participant: LeapModel {
    dynamic var person: Person?
    dynamic var identifierUsed: String?
    dynamic var participationString: String = Participation.unknown.rawValue
    dynamic var engagementString: String = Engagement.none.rawValue
    dynamic var importanceString: String = ParticipationImportance.unknown.rawValue
    dynamic var typeString: String = ParticipationType.unknown.rawValue
    dynamic var ownershipString: String = Ownership.unknown.rawValue

    static func makeMe() -> Participant {
        let value: ModelInitData = ["person": Person.me() ?? Person.makeMe()]
        return Participant(value: value)
    }

    var engagement: Engagement {
        get { return Engagement(rawValue: engagementString)! }
        set { engagementString = newValue.rawValue }
    }

    var participation: Participation {
        get { return Participation(rawValue: participationString)! }
        set { participationString = newValue.rawValue }
    }

    var importance: ParticipationImportance {
        get { return ParticipationImportance(rawValue: importanceString)! }
        set { importanceString = newValue.rawValue }
    }

    var type: ParticipationType {
        get { return ParticipationType(rawValue: typeString)! }
        set { typeString = newValue.rawValue }
    }

    var ownership: Ownership {
        get { return Ownership(rawValue: ownershipString)! }
        set { ownershipString = newValue.rawValue }
    }

    var isMe: Bool {
        return person?.isMe ?? false
    }

    var name: String {
        return person?.name ?? "Unknown"
    }

    var nameOrEmail: String? {
        return person?.name ?? person?.emails.first?.raw
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let p = object as? Participant {
            return p.person?.url == self.person?.url
        }
        return false
    }
}
