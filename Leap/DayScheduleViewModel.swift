//
//  ScheduleViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit

class DayScheduleViewModel: ViewModelUpdateable {
    weak var delegate: ViewModelDelegate?
    private let eventStore = EKEventStore() // should do this once per app load instead... somewhere?

    let dayId: Int

    init(dayId: Int) {
        self.dayId = dayId
        fetchEvents()
    }

    var numberOfEntries: Int {
        return entries.count
    }

    var entries: [ScheduleEntryViewModel] {
        // MOCKING OUT LIST OF ENTRIES
        
        var entries = [ScheduleEntryViewModel]()

        for _ in 0...3 {
            let eventEntry = ScheduleEntryViewModel.from(eventId: "")
            entries.append(eventEntry)
        }

        entries.append(ScheduleEntryViewModel.from(openTimeStart: nil, end: nil))

        let eventEntry = ScheduleEntryViewModel.from(eventId: "")
        entries.append(eventEntry)

        return entries
    }

    // vvv started to actually fetch events but haven't matched with above stuff yet
    private var localEvents = [EKEvent]()

    private func fetchEvents() {
        let calendar = NSCalendar.current
        let day = GregorianDay(id: dayId)
        let date = calendar.date(from: day.components)!
        let startOfDay = calendar.startOfDay(for: date)

        let nextDate = calendar.date(from: day.dayAfter.components)!
        let endOfDay = calendar.startOfDay(for: nextDate)

        let dayPredicate = eventStore.predicateForEvents(withStart: startOfDay,
                                                         end: endOfDay,
                                                         calendars: nil)

        self.localEvents = eventStore.events(matching: dayPredicate)
    }
}
