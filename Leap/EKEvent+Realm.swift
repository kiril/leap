//
//  EKEvent+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

// EKParticipant
// .isCurrentUser
// .name?
// .participantRole EKParticipantRole (unknown, required, optional, chair, nonParticipant)
// .participantStatus EKParticipantstatus (unknown, pending, accepted, declined, tentative, delegated, completed, inProcess)
//     note: "inProcess" and "completed" are about the event...???
// .participantType EKParticipantType (unknown, person, room, resource, group)
// .url

extension EKEvent {
    func asTemporality() -> Temporality? {
        if self.isAllDay {
            return self.allDayAsReminder()
        }
        return self.asEvent()
    }

    func asEvent() -> Event {
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
    }

    func allDayAsReminder() -> Reminder {
    }
}
