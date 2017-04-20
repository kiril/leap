//
//  ScheduleEntry.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

enum ScheduleEntry: Comparable {
    case event(entry: EventSurface)
    case openTime(entry: OpenTimeViewModel)

    static func from(eventId: String) -> ScheduleEntry {
        return from(event: EventSurface.load(byId: eventId)!)
    }

    static func from(event: EventSurface) -> ScheduleEntry {
        return .event(entry: event)
    }

    static func from(openTimeStart start: Date?, end: Date?) -> ScheduleEntry {
        let openTime = OpenTimeViewModel(startTime: start, endTime: end)
        return .openTime(entry: openTime)
    }

    static func == (lhs: ScheduleEntry, rhs: ScheduleEntry) -> Bool {
        switch lhs {
        case let .event(event):
            switch rhs {
            case let .event(event2):
                return event == event2
            default:
                return false
            }

        case let .openTime(time):
            switch rhs {
            case let .openTime(time2):
                return time == time2
            default:
                return false
            }
        }
    }

    static func < (lhs: ScheduleEntry, rhs: ScheduleEntry) -> Bool {
        switch lhs {
        case let .event(event):
            switch rhs {
            case let .event(event2):
                return event.startTime.value < event2.startTime.value
            case let .openTime(openTime2):
                guard let openStart = openTime2.startTime else { return false } // is this right?
                return event.startTime.value < openStart
            }

        case let .openTime(time):
            guard let openStart = time.startTime else { return true } // is this right?

            switch rhs {
            case let .event(event2):
                return openStart < event2.startTime.value
            case let .openTime(time2):
                guard let open2Start = time2.startTime else { return false } // is this right?
                return openStart < open2Start
            }
        }
    }
}
