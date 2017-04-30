//
//  DateFormatter+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/30/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension DateFormatter {
    static func shortTime(date: Date, appendAMPM: Bool = true) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        let amPm = hour >= 12 ? "pm" : "am"
        let simpleHour = hour == 12 ? 12 : hour % 12

        if minute > 0 {
            return appendAMPM ? "\(simpleHour):\(minute)\(amPm)" : "\(simpleHour):\(minute)"
        } else {
            return appendAMPM ? "\(simpleHour)\(amPm)" : "\(simpleHour)"
        }
    }
}
