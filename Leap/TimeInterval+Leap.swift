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
        var minutes = Int(self / 60)

        let minutesPerDay = 60 * 24

        var duration = ""

        let days = minutes / minutesPerDay
        minutes = minutes - (days * minutesPerDay)

        if days > 0 {
            duration += "\(days) days"
        }

        let hours = minutes / 60
        minutes = minutes - (hours * 60)

        if hours > 0 {
            if duration.characters.count > 0 {
                duration += " "
            }
            duration += "\(hours) hours"
        }

        if minutes > 0 {
            if duration.characters.count > 0 {
                duration += " "
            }
            duration += "\(minutes) minutes"
        }

        return duration
    }
}
