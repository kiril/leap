//
//  TimeInterval+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/30/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    func toString(short: Bool = false) -> String {
        // I'm in seconds
        let hourText = short ? "h" : "hour"
        let minuteText = short ? "m" : "minute"
        let dayText = short ? "d" : "day"

        var minutes = Int(self / 60)

        let minutesPerDay = 60 * 24

        var duration = ""

        let days = minutes / minutesPerDay
        minutes = minutes - (days * minutesPerDay)

        if days > 0 {
            if short {
                duration += "\(days)\(dayText)"
            } else {
                duration += "\(days) \(days.pluralize(string: dayText))"
            }
        }

        let hours = minutes / 60
        minutes = minutes - (hours * 60)

        if hours > 0 {
            if !duration.isEmpty {
                duration += " "
            }
            if short {
                duration += "\(hours)\(hourText)"
            } else {
                duration += "\(hours) \(hours.pluralize(string: hourText))"
            }
        }

        if minutes > 0 {
            if !duration.isEmpty {
                duration += " "
            }
            if short {
                duration += "\(minutes)\(minuteText)"
            } else {
                duration += "\(minutes) \(minutes.pluralize(string: minuteText))"
            }
        }

        return duration
    }

    var durationString: String { return toString() }

    var durationStringShort: String { return toString(short: true) }
}
