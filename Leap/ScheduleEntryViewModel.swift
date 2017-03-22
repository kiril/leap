//
//  ScheduleEntryViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

enum ScheduleEntryViewModel {
    case event(entry: EventShell)
    case openTime(entry: OpenTimeViewModel)

    static func from(eventId: String) -> ScheduleEntryViewModel {
        return .event(entry: EventShell(id: "", data:[:]))
    }

    static func from(openTimeStart start: Date?, end: Date?) -> ScheduleEntryViewModel {
        let openTime = OpenTimeViewModel(startTime: start, endTime: end)
        return .openTime(entry: openTime)
    }
}
