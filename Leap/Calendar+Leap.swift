//
//  Calendar+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension Calendar {

    func formatDisplayTime(from date: Date, needsAMPM: Bool) -> String {
        // maybe this can be done with a DateFormatter, but for now I'm
        // just going to code it up manually
        let hour = component(Calendar.Component.hour, from: date)
        let minute = component(Calendar.Component.minute, from: date)

        let hourString = String(format: "%d", (hour % 12))
        let minuteString = minute > 0 ? String(format: ":%02d", minute) : ""
        let ampmString = needsAMPM ? (hour < 12 ? "am" : "pm") : ""
        return hourString + minuteString + ampmString
    }

    func areOnDifferentDays(_ a: Date, _ b: Date) -> Bool {
        let ay = component(Calendar.Component.year, from: a)
        let am = component(Calendar.Component.month, from: a)
        let ad = component(Calendar.Component.day, from: a)

        let by = component(Calendar.Component.year, from: b)
        let bm = component(Calendar.Component.month, from: b)
        let bd = component(Calendar.Component.day, from: b)

        return ay != by || am != bm || ad != bd
    }
}
