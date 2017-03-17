//
//  EventViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import Foundation
import EventKit

class EventViewModel: ViewModelUpdateable {
    var delegate: ViewModelDelegate?

    let id: String

    init(id: String) {
        self.id = id
    }

    var title: String {
        return "My important meeting 👔"
    }

    var timeRange: String {
        return "10 - 11pm"

        /// SAVED FROM THE OLD VIEWCONTROLLER CODE:
        // should be moved to some place we can share with open time display too.

        //        let formatter = DateFormatter()
        //        formatter.dateFormat = "h:mma"
        //
        //        cell.timeLabel.text = "\(formatter.string(from: event.startDate))-\(formatter.string(from: event.endDate))".lowercased()
        /// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    }

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
    /// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
}
