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
        return [ScheduleEntry]()
    }
}
