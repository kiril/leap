//
//  EKEventStore+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

extension EKEventStore {

    func legacyCalendars() -> [LegacyCalendar] {
        let eventCalendars = self.calendars(for: EKEntityType.event)
        let reminderCalendars = self.calendars(for: EKEntityType.reminder)

        var legacy = [LegacyCalendar]()
        for calendar in eventCalendars {
            legacy.append(calendar.asLegacyCalendar())
        }
        for calendar in reminderCalendars {
            legacy.append(calendar.asLegacyCalendar())
        }
        return legacy
    }
}
