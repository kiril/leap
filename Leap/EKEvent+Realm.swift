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
        if self.isAllDay {
            return self.asReminder()
        } else {
            switch self.availability {
            case .free:
                return self.asReminder()
            default:
                return self.asEvent()
            }
        }
    }

    func asEvent() -> Event {
        let data: [String:Any?] = [
            "id": self.calendarItemIdentifier,
            "externalId": self.calendarItemExternalIdentifier,
            "title": self.title,
            "detail": self.notes,
            "startTime": self.startDate.secondsSinceReferenceDate,
            "endTime": self.endDate.secondsSinceReferenceDate,
            "locationString": self.location,
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "modalityString": EventModality.inPerson.rawValue,
            "externalURL": self.url
        ]

        // TODO: Ownership needs to be adjusted for shared calendar data (not for the owner, but for the consumer who's not an 'invitee' in that case)

        let event = Event(value: data)

        var organizerId: String? = nil

        let availability: EKEventAvailability = self.availability

        if let organizer = self.organizer, let participant = organizer.asParticipant(availability: availability, ownership: Ownership.organizer) {
            if let person = participant.person {
                organizerId = person.id
            }
            event.participants.append(participant)
        }

        if let attendees = self.attendees {
            for attendee in attendees {
                if let participant = attendee.asParticipant(availability: availability, ownership: Ownership.invitee), let person = participant.person, person.id != organizerId {
                    event.participants.append(participant)
                } else if let reservation = attendee.asRoomReservation(for: event) {
                    event.reservations.append(reservation)
                } else if let reservation = attendee.asResourceReservation(for: event) {
                    event.reservations.append(reservation)
                }
            }
        }

        if let ekAlarms = self.alarms {
            for alarm in ekAlarms {
                event.alarms.append(alarm.asAlarm())
            }
        }

        if self.hasRecurrenceRules, let rules = self.recurrenceRules {
            let rule = rules[0] // despite the interface, documentation says there can Only Be One <boom boom>
            var series = Series.by(id: event.id)
            if series == nil {
                series = Series(value: ["id": event.id,
                                        "title": event.title])
                let templateData: [String:Any?] = ["title": event.title,
                                                   "duration": event.duration,
                                                   "detail": event.detail,
                                                   "locationString": event.locationString,
                                                   "modalityString": event.modalityString]
                series!.template = EventTemplate(value: templateData)
                series!.recurrence = rule.asRecurrence(ofEvent: event)
            }

            if let series = series {
                event.series = series
                event.template = series.template
            }
        }

        return event
    }

    func asReminder() -> Reminder {
        let data: [String:Any?] = [
            "title": self.title
        ]
        //let availability: EKEventAvailability = EKEventAvailability.free
        return Reminder(value: data)
    }
}
