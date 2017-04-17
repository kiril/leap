//
//  EKEvent+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit
import RealmSwift

extension EKEvent {

    func asTemporality() -> Temporality? {
        var t: Temporality!

        if self.isAllDay {
            t = self.asReminder()
        } else {
            switch self.availability {
            case .free:
                t = self.asReminder()
            default:
                t = self.asEvent()
            }
        }

        let availability: EKEventAvailability = self.availability

        var organizerId: String? = nil

        if let organizer = self.organizer, let participant = organizer.asParticipant(availability: availability, ownership: Ownership.organizer) {
            if let person = participant.person {
                organizerId = person.id
            }
            t.participants.append(participant)
        }

        if let attendees = self.attendees {
            for attendee in attendees {
                if let participant = attendee.asParticipant(availability: availability, ownership: Ownership.invitee), let person = participant.person, person.id != organizerId {
                    t.participants.append(participant)
                } else if let event = t as? Event,
                    let reservation = attendee.asRoomReservation(for: event) {
                    event.reservations.append(reservation)
                } else if let event = t as? Event,
                    let reservation = attendee.asResourceReservation(for: event) {
                    event.reservations.append(reservation)
                }
            }
        }

        if let ekAlarms = self.alarms {
            for alarm in ekAlarms {
                t.alarms.append(alarm.asAlarm())
            }
        }


        if hasRecurrenceRules, let rules = recurrenceRules {
            var series = Series.by(id: t.id)
            if series == nil {
                series = rules[0].asSeries(t)
                try! Realm.user().write {
                    Realm.user().add(series!, update: true)
                }
            }

            if let series = series {
                t.series = series
                t.template = series.template
            }
        }

        return t
    }

    func asEvent() -> Event {
        let data: [String:Any?] = [
            "id": self.eventIdentifier,
            "title": self.title,
            "detail": self.notes,
            "startTime": self.startDate.secondsSinceReferenceDate,
            "endTime": self.endDate.secondsSinceReferenceDate,
            "locationString": self.location,
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "modalityString": EventModality.inPerson.rawValue,
            "externalURL": self.url?.absoluteString,
            "wasDetached": self.isDetached,
        ]

        return Event(value: data)
    }

    var hackyRecurranceIdSuffix: String {
        // The purpose of this is to force duplicate any EKEvents that are returned with recurrances,
        // to force them to display until we get recurrence-based queries up and running.
        if self.hasRecurrenceRules {
            return "+hacky_recurrance_id_\(self.startDate.secondsSinceReferenceDate)"
        }
        return ""
    }

    func asReminder() -> Reminder {
        let data: [String:Any?] = [
            "title": self.title,
            "detail": self.notes,
            "startTime": self.startDate.secondsSinceReferenceDate,
            "locationString": self.location,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "externalURL": self.url?.absoluteString,
            "wasDetached": self.isDetached,
            ]

        return Reminder(value: data)
    }
}
