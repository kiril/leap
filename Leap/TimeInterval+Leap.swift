//
//  TimeInterval+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/30/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    var durationString: String {
        // I'm in seconds
        let hourText = "hour"
        let minuteText = "minute"
        let dayText = "day"

        var minutes = Int(self / 60)

        let minutesPerDay = 60 * 24

        var duration = ""

        let days = minutes / minutesPerDay
        minutes = minutes - (days * minutesPerDay)

        if days > 0 {
            duration += "\(days) \(days.pluralize(string: dayText))"
        }

        let hours = minutes / 60
        minutes = minutes - (hours * 60)

        if hours > 0 {
            if !duration.isEmpty {
                duration += " "
            }
            duration += "\(hours) \(hours.pluralize(string: hourText))"
        }

        if minutes > 0 {
            if !duration.isEmpty {
                duration += " "
            }
            duration += "\(minutes) \(minutes.pluralize(string: minuteText))"
        }

        return duration
    }
}
