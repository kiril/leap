//
//  DayScheduleSurface.swift
//  Leap
//
//  Created by Chris Ricca on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

class DayScheduleSurface: Surface {

    override var type: String { return "dayScheduleSurface" }

    private let eventStore = EKEventStore() // should do this once per app load instead... somewhere?

    let entries = ComputedProperty<[ScheduleEntry], DayScheduleSurface>("entries", DayScheduleSurface.scheduleEntries)

    var numerOfEntries: Int {
        return entries.value.count
    }

    private static func scheduleEntries(schedule: DayScheduleSurface) -> [ScheduleEntry] {
        return [ScheduleEntry]()
    }
}
