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

    func getOrigin(in calendar: EKCalendar) -> Origin {
        if let organizer = self.organizer, organizer.isCurrentUser {
            return .personal

        } else if let _ = me {
            if attendees!.count > 1 {
                return .invite
            } else {
                return .personal
            }

        } else if hasAttendees { // and none of them is me
            return .share

        } else {
            if calendar.isSubscribed {
                return .subscription
            } else if calendar.isImmutable {
                return .share
            } else {
                switch calendar.type {
                case .birthday:
                    return .share

                case .subscription:
                    return .subscription

                case .local:
                    return .personal

                default:
                    return .unknown
                }
            }
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

    func addCommonData(_ data: ModelInitData, in calendar: EKCalendar) -> ModelInitData {
        var common: ModelInitData = [
            "id": self.cleanId,
            "title": self.title,
            "detail": self.notes,
            "locationString": self.location,
            "modalityString": self.modality.rawValue,
            "originString": self.getOrigin(in: calendar).rawValue,
            "participants": self.getParticipants(),
            "linkedCalendarIds": [calendar.asLinkId()],
            "alarms": self.getAlarms(),
        ]
        for (key, value) in data {
            common[key] = value
        }
        return common
    }

    func asTemplate(in calendar: EKCalendar) -> Template {
        let hour = Calendar.current.component(.hour, from: startDate)
        let minute = Calendar.current.component(.minute, from: startDate)
        let durationInSeconds = endDate.secondsSinceReferenceDate - startDate.secondsSinceReferenceDate
        let durationInMinutes = durationInSeconds / 60

        let data = addCommonData(["startHour": hour,
                                  "startMinute": minute,
                                  "durationMinutes": durationInMinutes,
                                  "seriesId": cleanId,
                                  "isTentative": self.isTentative], in: calendar)
        return Template(value: data)
    }
    
    func asEvent(in calendar: EKCalendar) -> Event {
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
            ], in: calendar)

        return Event(value: data)
    }

    func asReminder(in calendar: EKCalendar) -> Reminder {
        let data = addCommonData([
            "startTime": self.startDate.secondsSinceReferenceDate,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "externalURL": self.url?.absoluteString,
            "wasDetached": self.isDetached,
            ], in: calendar)

        return Reminder(value: data)
    }
}
