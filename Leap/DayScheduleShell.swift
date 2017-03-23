//
//  DayScheduleShell.swift
//  Leap
//
//  Created by Chris Ricca on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

class DayScheduleShell: Shell {

    override var type: String { return "dayScheduleShell" }

    private let eventStore = EKEventStore() // should do this once per app load instead... somewhere?

    let entries = ComputedProperty<[ScheduleEntry], DayScheduleShell>("entries", DayScheduleShell.scheduleEntries)

    var numerOfEntries: Int {
        return entries.value.count
    }

    private static func scheduleEntries(schedule: DayScheduleShell) -> [ScheduleEntry] {
        // MOCKING OUT LIST OF ENTRIES

        var entries = [ScheduleEntry]()

        for i in 2...4 {
            let event = EventShell(mockData: ["title": "testing", "time_range": "\(i)pm - \(i+1)pm"])
            let eventEntry = ScheduleEntry.from(event: event)
            entries.append(eventEntry)
        }

        entries.append(ScheduleEntry.from(openTimeStart: nil, end: nil))

        let eventEntry = ScheduleEntry.from(eventId: "")
        entries.append(eventEntry)
        
        return entries
    }
}
