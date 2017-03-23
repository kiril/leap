//
//  ScheduleEntryViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

enum ScheduleEntry {
    case event(entry: EventShell)
    case openTime(entry: OpenTimeViewModel)

    static func from(eventId: String) -> ScheduleEntry {
        return from(event: EventShell(id: eventId, data:[:])) // find?
    }

    static func from(event: EventShell) -> ScheduleEntry {
        return .event(entry: event)
    }

    static func from(openTimeStart start: Date?, end: Date?) -> ScheduleEntry {
        let openTime = OpenTimeViewModel(startTime: start, endTime: end)
        return .openTime(entry: openTime)
    }
}
