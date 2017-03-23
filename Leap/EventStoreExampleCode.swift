//
//  EventViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import Foundation
import EventKit

class EventStoreExampleCode {
    /// SAVED FROM THE OLD VIEWCONTROLLER CODE:
    let eventStore = EKEventStore()

    var eventsForTheDay: [EKEvent] {
        let calendar = NSCalendar.current
        let startOfDay = calendar.startOfDay(for: calendar.today)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!

        let todayPredicate = eventStore.predicateForEvents(withStart: startOfDay,
                                                           end: endOfDay,
                                                           calendars: nil)

        return eventStore.events(matching: todayPredicate)
    }

    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { (success, error) in
            if success {
                // ...
            }
        }
    }


    // SAVED FROM THE OLD DAY SCHEDULE VIEW MODEL
    private var localEvents = [EKEvent]()

    private func fetchEventsFor(dayId: Int) {
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
