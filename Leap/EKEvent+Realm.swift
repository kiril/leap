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
            if !attendees!.isEmpty {
                return .invite
            } else {
                return .personal
            }

        } else if hasAttendees { // and none of them is me
            return .share

        } else {
            if calendar.isSubscribed {
                return .subscription

            } else if calendar.isGmailPrimary || calendar.isYahooPrimary {
                return .personal

            } else if calendar.isGmailSecondary {
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

    var rule: EKRecurrenceRule? { return self.hasRecurrenceRules ? self.recurrenceRules?[0] : nil }

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

    var isMultidayReminder: Bool {
        guard self.isAllDay else { return false }
        return Calendar.current.areOnDifferentDays(startDate, endDate)
    }

    func getAlarms() -> [Alarm] {
        var alarms: [Alarm] = []

        if let ekAlarms = self.alarms {
            for alarm in ekAlarms {
                alarms.append(alarm.asAlarm())
            }
        }

        return alarms
    }

    func getParticipants(origin: Origin) -> [Participant] {
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

        if participants.isEmpty && origin == .personal {
            let me = Participant.makeMe()
            me.engagement = .engaged
            me.importance = .critical
            me.ownership = .organizer
            me.type = .unknown
            participants.append(me)
        }

        if let me = me, me.ownership == .organizer && me.engagement == .undecided {
            me.engagement = .engaged
        }
        
        return participants
    }

    func addCommonData(_ data: ModelInitData, in calendar: EKCalendar) -> ModelInitData {
        let origin = getOrigin(in: calendar)
        let participants = self.getParticipants(origin: origin)
        var common: ModelInitData = [
            "id": self.cleanId,
            "title": self.title,
            "detail": self.notes,
            "locationString": self.location,
            "modalityString": self.modality.rawValue,
            "originString": origin.rawValue,
            "participants": participants,
            "linkedCalendarIds": [calendar.asLinkId()],
            "alarms": self.getAlarms(),
            "engagementString": (participants.me?.engagement ?? .none).rawValue,
            "statusString": self.objectStatus.rawValue,
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
                                  "reminderTypeString": self.reminderType.rawValue,
                                  "isTentative": self.isTentative], in: calendar)
        return Template(value: data)
    }
    
    func asEvent(in calendar: EKCalendar, detached: Bool = false, from series: Series? = nil, eventId: String? = nil) -> Event {
        var data = addCommonData([
            "startTime": self.startDate.secondsSinceReferenceDate,
            "endTime": self.endDate.secondsSinceReferenceDate,
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "externalURL": self.url?.absoluteString,
            "wasDetached": detached,
            "isTentative": self.isTentative,
            "firmnessString": self.firmness.rawValue,
            "seriesId": series?.id,
            ], in: calendar)

        if detached, let id = eventId {
            data["id"] = id
        }

        return Event(value: data)
    }

    func asReminder(in calendar: EKCalendar, detached: Bool = false, from series: Series? = nil, eventId: String? = nil) -> Reminder {
        var data = addCommonData([
            "startTime": self.startDate.secondsSinceReferenceDate,
            "endTime": self.reminderType == .time ? self.endDate.secondsSinceReferenceDate : 0,
            "legacyTimeZone": TimeZone.from(self.timeZone),
            "remoteCreated": self.creationDate,
            "remoteModified": self.lastModifiedDate,
            "externalURL": self.url?.absoluteString,
            "wasDetached": detached,
            "seriesId": series?.id,
            "typeString": self.reminderType.rawValue,
            ], in: calendar)

        if detached, let id = eventId {
            data["id"] = id
        }

        return Reminder(value: data)
    }

    func asSeries(in calendar: EKCalendar) -> Series {
        let template = self.asTemplate(in: calendar)
        let recurrence = self.asRecurrence()
        let data = addCommonData(["typeString": CalendarItemType.reminder.rawValue,
                                  "recurrence": recurrence,
                                  "template": template],
                                 in: calendar)
        return Series(value: data)
    }

    func asRecurrence() -> Recurrence {
        return Recurrence(value: ["frequencyRaw": Frequency.daily.rawValue,
                                  "count": Calendar.current.daysBetween(startDate, and: endDate)])
    }

    func isDetachedForm(of series: Series) -> Bool {

        let minutes = (endDate.secondsSinceReferenceDate - startDate.secondsSinceReferenceDate) / 60

        if !series.recurs(exactlyAt: startDate, ignoreActiveRange: true) {
            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.dayAfter(start)
            let range = TimeRange(start: start, end: end)!
            print("DETACHED: \(DateFormatter.shortFormat(startDate)) isn't \(String(describing: series.template.startTime(in: range)))")
            return true
        }

        if title != series.template.title || minutes != series.template.durationMinutes {
            print("DETACHED \(title): Title/Duration change")
            return true
        }

        return series.status != objectStatus
    }

    var objectStatus: ObjectStatus {
        switch status {
        case .canceled:
            return .archived
        default:
            if let me = self.me, me.getEngagement(availability: availability) == .disengaged {
                return .archived
            }
            return .active
        }
    }

    var reminderType: ReminderType {
        return self.isAllDay ? .day : .time
    }
}
