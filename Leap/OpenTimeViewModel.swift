//
//  OpenTimeViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

struct OpenTimeViewModel: Equatable {
    let startTime: Date?
    let endTime: Date?
    var durationSeconds: Int {
        return (endTime!.secondsSinceReferenceDate - startTime!.secondsSinceReferenceDate)
    }

    init(startTime: Date?, endTime: Date?) {
        self.startTime = startTime
        self.endTime = endTime
    }

    init() {
        self.init(startTime: nil, endTime: nil)
    }

    static func == (lhs: OpenTimeViewModel, rhs: OpenTimeViewModel) -> Bool {
        return lhs.startTime == rhs.startTime && lhs.endTime == rhs.endTime
    }

    var timeRange: String {
        let calendar = Calendar.current

        guard let startTime = startTime else {
            guard let endTime = endTime else { return "" }

            let to = calendar.formatDisplayTime(from: endTime, needsAMPM: true)
            return "Until \(to)"
        }
        guard let endTime = endTime else {
            let from = calendar.formatDisplayTime(from: startTime, needsAMPM: true)
            return "\(from) onwards"
        }

        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)

        let crossesNoon = startHour < 12 && endHour >= 12

        let from = calendar.formatDisplayTime(from: startTime, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: endTime, needsAMPM: true)

        return "\(from) - \(to)"
    }

    var range: TimeRange? {
        guard   let start = startTime,
                let end = endTime else { return nil }
        return TimeRange(start: start, end: end)
    }

    var possibleEventIds = [String]()

    var possibleEventCount: Int {
        return possibleEvents.count
    }
    
    var possibleEvents: [EventSurface] {
        return possibleEventIds.flatMap() { event(forId: $0) }
    }

    func possibleEvent(atIndex index: Int) -> EventSurface? {
        return event(forId: possibleEventIds[index])
    }

    func event(forId eventOrSeriesId: String) -> EventSurface? {
        return  EventSurface.load(byId: eventOrSeriesId) ??
                RecurringEventSurface.load(seriesId: eventOrSeriesId, in: range!)
    }
}
