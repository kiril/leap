//
//  Participant.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


// TODO: what of resources? rooms?


enum Participation: String {
    case unknown  = "unknown"
    case attendee = "attendee"
    case observer = "observer"
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


protocol Participant {
    var person: Person? { get }
    var identifierUsed: String? { get } // the email used to invite them...?
    var participation: Participation { get set }
    var engagement: Engagement { get set }
    var importance: ParticipationImportance { get set }
    var type: ParticipationType { get set }
}


class _ParticipantBase: LeapModel {
    dynamic var person: Person?
    dynamic var identifierUsed: String?
    dynamic var participationString: String = Participation.unknown.rawValue
    dynamic var engagementString: String = Engagement.none.rawValue
    dynamic var importanceString: String = ParticipationImportance.unknown.rawValue
    dynamic var typeString: String = ParticipationType.unknown.rawValue

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
}
