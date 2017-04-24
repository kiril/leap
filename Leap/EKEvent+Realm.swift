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

enum CalendarItemType: String {
    case event
    case reminder
}

extension EKEvent {

    var type: CalendarItemType {
        switch self.availability {
        case .free:
            return .reminder
        default:
            return self.isAllDay ? .reminder : .event
        }
    }

    var modality: EventModality {
        return EventModality.inPerson
    }

    var isRecurring: Bool {
        return hasRecurrenceRules && self.recurrenceRules != nil
    }

    var me: EKParticipant? {
        if let attendees = self.attendees {
            for attendee in attendees {
                if attendee.isCurrentUser {
                    return attendee
                }
            }
        }
        return nil
    }

    var origin: Origin {
        if let organizer = self.organizer, organizer.isCurrentUser {
            return .personal
        } else if let _ = me {
            return .invite
        } else {
            return .unknown
        }
    }

    var rule: EKRecurrenceRule? { return self.recurrenceRules?[0] }

    var cleanId: String {
        var id = self.eventIdentifier
        if id.contains("/RID=") {
            id = id.components(separatedBy: "/RID")[0]
        }
        return id
    }

    var firmness: Firmness {
        switch availability {
        case .tentative, .free:
            return .soft
        default:
            return .firm
        }
    }

    var isTentative: Bool { return self.availability == .tentative }

    func getAlarms() -> [Alarm] {
        var alarms: [Alarm] = []

        if let ekAlarms = self.alarms {
            for alarm in ekAlarms {
                alarms.append(alarm.asAlarm())
            }
        }

        return alarms
    }


    func getParticipants() -> [Participant] {
        var participants: [Participant] = []

        let availability: EKEventAvailability = self.availability

        var me: Participant?
        var organizerId: String? = nil
        if let organizer = self.organizer, let participant = organizer.asParticipant(availability: availability, ownership: Ownership.organizer) {
            if let person = participant.person {
                organizerId = person.id
            }
            participants.append(participant)
            if participant.isMe {
                me = participant
            }
        }

        if let attendees = self.attendees {
            for attendee in attendees {
                if let participant = attendee.asParticipant(availability: availability, ownership: Ownership.invitee),
                    let person = participant.person,
                    person.id != organizerId {
                    participants.append(participant)
                    if participant.isMe {
                        me = participant
                    }
                }
            }
        }

        if participants.count == 1 && participants[0].isMe {
            switch availability {
            case .busy, .unavailable, .notSupported:
                participants[0].engagement = .engaged
            default:
                participants[0].engagement = .tracking
            }
        }

        if let me = me, me.ownership == .organizer && me.engagement == .undecided {
            me.engagement = .engaged
        }
        
        return participants
    }

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

        t.participants.append(objectsIn: getParticipants())
        t.origin = self.origin
        t.alarms.append(objectsIn: getAlarms())

        return t
    }

    func addCommonData(_ data: ModelInitData) -> ModelInitData {
        var common: ModelInitData = [
            "id": self.cleanId,
            "title": self.title,
            "detail": self.notes,
            "locationString": self.location,
            "modalityString": self.modality.rawValue,
            "originString": self.origin.rawValue,
        ]
        for (key, value) in data {
            common[key] = value
        }
        return common
    }

    func asTemplate() -> Template {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startDate)
        let minute = calendar.component(.minute, from: startDate)
        let durationInSeconds = endDate.secondsSinceReferenceDate - startDate.secondsSinceReferenceDate
        let durationInMinutes = durationInSeconds / 60

        let data = addCommonData(["startHour": hour,
                                  "startMinute": minute,
                                  "durationMinutes": durationInMinutes,
                                  "seriesId": cleanId,
                                  "isTentative": self.isTentative])
        return Template(value: data)
    }
    
    func asEvent() -> Event {
        let data = addCommonData([
            "startTime": self.startDate.secondsSinceReferenceDate,
            "endTime": self.endDate.secondsSinceReferenceDate,
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "externalURL": self.url?.absoluteString,
            "wasDetached": self.isDetached,
            "isTentative": self.isTentative,
            "firmnessString": self.firmness.rawValue,
        ])

        return Event(value: data)
    }

    func asReminder() -> Reminder {
        let data = addCommonData([
            "startTime": self.startDate.secondsSinceReferenceDate,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "externalURL": self.url?.absoluteString,
            "wasDetached": self.isDetached,
            ])

        return Reminder(value: data)
    }
}
