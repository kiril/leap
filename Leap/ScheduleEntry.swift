//
//  ScheduleEntry.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit


protocol Schedulable {
}


enum ScheduleEntry: Comparable, Schedulable {
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

class ScheduleEntryWrapper: IGListDiffable {
    let scheduleEntry: ScheduleEntry

    init(scheduleEntry: ScheduleEntry) {
        self.scheduleEntry = scheduleEntry
    }

    func diffIdentifier() -> NSObjectProtocol {
        switch scheduleEntry {
        case .event(entry: let event):
            return NSNumber(value: event.id.hash)
        case .openTime(entry: let openTime):
            return NSNumber(value: openTime.timeRange.hash)
        }
    }

    func isEqual(toDiffableObject object: IGListDiffable?) -> Bool {
        guard let otherEntryWrapper = object as? ScheduleEntryWrapper else {
            return false
        }
        let otherEntry = otherEntryWrapper.scheduleEntry

        switch (scheduleEntry, otherEntry) {
        case let (.event(a), .event(b)):
            return (a == b) && (a.userResponse.value == b.userResponse.value) && (a.isInConflict == b.isInConflict) && (a.temporarilyForceDisplayResponseOptions == b.temporarilyForceDisplayResponseOptions) // this is horrible, but that transient state of the temporary thing lets me make sure we re-render
        case let (.openTime(a), .openTime(b)):
            return a.timeRange == b.timeRange
        default:
            return false
        }
    }
}

protocol ScheduleEntryProtocol {}
extension ScheduleEntry: ScheduleEntryProtocol {}
extension Array where Element: ScheduleEntryProtocol {
    func diffable() -> [ScheduleEntryWrapper] {
        var wrapped = [ScheduleEntryWrapper]()

        let entries = self as! [ScheduleEntry]

        for entry in entries {
            wrapped.append(ScheduleEntryWrapper(scheduleEntry: entry))
        }

        return wrapped
    }
}
