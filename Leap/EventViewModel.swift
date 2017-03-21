//
//  EventViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import Foundation
import EventKit

enum InvitationResponse {
    case none,
    yes,
    no,
    maybe
}

enum TimePerspective {
    case past,
    future,
    current
}

class EventViewModel: ViewModelUpdateable {
    var delegate: ViewModelDelegate?

    let id: String

    init(id: String) {
        self.id = id
    }

    var title: String {
        return "My important meeting 👔"
    }

    var description: String {
        return ""
    }

    var allDay: Bool {
        return false
        // is this a different class type?
    }

    var startTime: Date {
        return Date()
    }

    var endTime: Date {
        return Date()
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

    var userIgnored: Bool {
        return false
    }

    var userInvitationResponse: InvitationResponse {
        // for events for which there is an open invitation
        return .none
    }

    var userIsInvited: Bool {
        return true
    }

    var isUnresolved: Bool {
        return userInvitationResponse == .none && !userIgnored
    }

    var happeningIn: TimePerspective {
        return .future 
    }

    var percentElapsed: Float {
        return 0.85
    }

//    var userPinned: Bool {
//        return false
//    }


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


    /// NOT Handled yet in this ViewModel (yet):
    /// [ ] - all day events, start / end
    /// [ ] - shared calendar events (how to join. that vs. invitations)
    /// [ ] - pins
}
