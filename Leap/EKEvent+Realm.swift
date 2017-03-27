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
    static func engagement(for type: Any,
                           from status: EKEventStatus,
                           and availability: EKEventAvailability) -> Engagement {
        switch status {
        case .none:
            return Engagement.undecided // I think this is right
        case .confirmed:
            if type is Reminder.Type {
                // reminders are by definition sorta ephemeral,
                // so it doesn't matter how the event was originally configured
                return Engagement.engaged
            } else {
                // Events are intended to be real things, so we're going to
                // only show them as real things in your calendar if they're
                // actually concrete things that'll actually happen (as distinct
                // from Reminders as above)
                switch availability {
                case .busy, .unavailable, .notSupported:
                    return Engagement.engaged
                case .tentative, .free:
                    return Engagement.tracking
                }
            }
        case .tentative:
            return Engagement.tracking
        case .canceled:
            return Engagement.disengaged
        }
    }

    func asTemporality(in realm: Realm) -> Temporality? {
        if self.isAllDay {
            return self.asReminder(in: realm)
        } else {
            switch self.availability {
            case .free:
                return self.asReminder(in: realm)
            default:
                return self.asEvent(in: realm)
            }
        }
    }

    func asEvent(in realm: Realm) -> Event {
        // .title
        // .location?
        // .creationDate?
        // .lastModifiedDate?
        // .timeZone?
        // .url?
        // .hasNotes
        // .notes?
        // .hasAttendees
        // .attendees [EKParticipant]?
        // .hasAlarms
        // .alarms [EKAlarm]?
        // .hasRecurrenceRules
        // .recurrenceRules [EKRecurrenceRule]?

        // .availability EKEventAvailability (notSupported, busy, free, tentative, unavailable)
        // .occurrenceDate (the original date of a recurrence)
        // .isAllDay
        // .startDate
        // .endDate
        // .isDetached -> if it's a modified instance of a repeating event
        // .organizer EKParticipant?
        // .status EKEventStatus (none, confirmed, tentative, canceled)
        let data: [String:Any?] = [
            "id": self.calendarItemIdentifier,
            "externalId": self.calendarItemExternalIdentifier,
            "title": self.title,
            "detail": self.notes,
            "startTime": self.startDate,
            "endTime": self.endDate,
            "locationString": self.location,
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "legacyTimeZone": self.timeZone,
            "modalityString": EventModality.inPerson.rawValue,
            "externalURL": self.url,
            "engagementString": EKEvent.engagement(for: Event.self, from: self.status, and: self.availability)
        ]

        let event = Event(value: data)

        var organizerId: String? = nil

        if let organizer = self.organizer, let participant = organizer.asParticipant(in: realm) {
            if let person = participant.person {
                organizerId = person.id
            }
            event.participants.append(participant)
        }

        if let attendees = self.attendees {
            for attendee in attendees {
                if let participant = attendee.asParticipant(in: realm), let person = participant.person, person.id != organizerId {
                    event.participants.append(participant)
                } else if let reservation = attendee.asRoomReservation(in: realm, for: event) {
                    event.reservations.append(reservation)
                } else if let reservation = attendee.asResourceReservation(in: realm, for: event) {
                    event.reservations.append(reservation)
                }
            }
        }

        if let ekAlarms = self.alarms {
            for alarm in ekAlarms {
                event.alarms.append(alarm.asAlarm(in: realm))
            }
        }

        if self.hasRecurrenceRules, let rules = self.recurrenceRules {
            let rule = rules[0] // despite the interface, documentation says there can Only Be One <boom boom>
            var series: Series? = realm.series(byId: event.id)
            if series == nil {
                series = Series(value: ["id": event.id,
                                        "title": event.title])
                let templateData: [String:Any?] = ["title": event.title,
                                                   "duration": event.duration,
                                                   "detail": event.detail,
                                                   "locationString": event.locationString,
                                                   "modalityString": event.modalityString]
                series!.template = EventTemplate(value: templateData)
                series!.recurrence = rule.asRecurrence()
            }

            if let series = series {
                event.series = series
                event.template = series.template
            }
        }

        return event
    }

    func asReminder(in realm: Realm) -> Reminder {
        let data: [String:Any?] = [
            "title": self.title
        ]
        return Reminder(value: data)
    }
}
