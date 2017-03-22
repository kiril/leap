//
//  EventViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import Foundation
import EventKit

struct EventStoreExampleCode {
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
}
