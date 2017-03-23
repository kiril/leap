//
//  UserEvent.swift
//  Leap
//
//  Created by Kiril Savino on 3/23/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


/**
 * How is this even on my radar?
 */
enum EventRelationship: String {
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
enum EventEngagement: String {
    case undecided   = "undecided" // hasn't dealt with it
    case tracking    = "tracking" // maybe/ignored / in the background
    case engaged     = "engaged" // attending / committed
    case disengaged  = "disengaged" // declined / deleted
    case none        = "none" // as above, a neutral status that is unlikely to be stored but useful for completeness
}


/**
 * Much of what we'll actually be dealing with, however, is this User's
 * relationship to a given event.
 */
class UserEvent: LeapModel {
    dynamic var event: Event?

    dynamic var relationshipString = EventRelationship.creator.rawValue // right default?
    dynamic var engagementString = EventEngagement.undecided.rawValue

    var relationship: EventRelationship {
        get { return EventRelationship(rawValue: relationshipString)! }
        set { relationshipString = newValue.rawValue }
    }

    var engagement: EventEngagement {
        get { return EventEngagement(rawValue: engagementString)! }
        set { engagementString = newValue.rawValue }
    }
}
