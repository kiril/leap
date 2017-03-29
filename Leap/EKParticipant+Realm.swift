//
//  EKParticipant+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit
import RealmSwift

// EKParticipant
// .isCurrentUser
// .name?
// .participantRole EKParticipantRole (unknown, required, optional, chair, nonParticipant)
// .participantStatus EKParticipantstatus (unknown, pending, accepted, declined, tentative, delegated, completed, inProcess)
//     note: "inProcess" and "completed" are about the event...???
// .participantType EKParticipantType (unknown, person, room, resource, group)
// .url

extension EKParticipant {
    func getParticipation() -> Participation {
        // .attenedee, .observer, .unknown
        switch self.participantRole {
        case .required, .chair:
            return .attendee
        case .optional, .nonParticipant, .unknown:
            return .observer
        }
    }

    func getImportance() -> ParticipationImportance {
        switch self.participantRole {
        case .required, .chair:
            return ParticipationImportance.critical
        case .optional:
            return ParticipationImportance.valued
        case .nonParticipant, .unknown:
            return ParticipationImportance.optional
        }
    }

    func getParticipationType() -> ParticipationType {
        return ParticipationType.inPerson // I don't think there's any info that reflects otherwise in existing EK
    }

    func getEngagement() -> Engagement {
        switch self.participantStatus {
        case .unknown, .pending:
            return Engagement.undecided
        case .accepted, .completed, .inProcess:
            return Engagement.engaged
        case .declined:
            return Engagement.disengaged
        case .tentative:
            return Engagement.tracking
        case .delegated:
            return Engagement.engaged
        }
    }

    func asParticipant() -> Participant? {
        let realm = Realm.user()
        guard self.participantType == EKParticipantType.person else {
            return nil
        }

        var person: Person?
        if self.isCurrentUser {
            person = Person.me()
            if person == nil {
                let data: [String:Any?] = ["isMe": true, "url": self.url]
                person = Person(value: data)
                person!.setNameComponents(from: self.name)
            }
        } else {
            person = realm.objects(Person.self).filter("url = '\(self.url)'").first
        }

        if person == nil {
            let data: [String:Any?] = ["url": self.url]
            person = Person(value: data)
            person!.setNameComponents(from: self.name)
        }
        // TODO: there's some kind of "contactPredicate" on the EKParticipant that might let me
        //       figure out who this really is, if I access contact data...
        // TODO: identifierUsed on participant... should be the email we invited by, for instance.

        let data: [String:Any?] = ["person": person,
                                   "participationString": getParticipation().rawValue,
                                   "importanceString": getImportance().rawValue,
                                   "engagementString": getEngagement().rawValue,
                                   "typeString": getParticipationType().rawValue
                                   ]
        return Participant(value: data)
    }

    func asRoomReservation(for event: Event) -> Reservation? {
        let realm = Realm.user()
        guard self.participantType == EKParticipantType.room, let name = self.name else {
            return nil
        }

        let query: Results<Room> = realm.objects(Room.self)
        var room: Room? = query.filter("name = %@", name).first
        if room == nil {
            room = Room(value: ["name": self.name, "typeString": "room"])
        }

        return Reservation(value: ["resource": room as Any?,
                                   "startTime": event.startTime as Any?,
                                   "endTime": event.endTime as Any?])
    }

    func asResourceReservation(for event: Event) -> Reservation? {
        guard self.participantType == EKParticipantType.resource, let name = self.name else {
            return nil
        }

        let realm = Realm.user()

        let query: Results<Resource> = realm.objects(Resource.self)
        var resource: Resource? = query.filter("name = %@", name).first
        if resource == nil {
            resource = Resource(value: ["name": self.name, "typeString": "equipment"])
        }

        return Reservation(value: ["resource": resource as Any?,
                                   "startTime": event.startTime as Any?,
                                   "endTime": event.endTime as Any?])
    }
}
