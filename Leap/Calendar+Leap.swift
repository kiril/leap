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

        let nonMilitaryHour = hour == 12 ? 12 : hour % 12

        let hourString = String(format: "%d", nonMilitaryHour)
        let minuteString = minute > 0 ? String(format: ":%02d", minute) : ""
        let ampmString = needsAMPM ? (hour < 12 ? "am" : "pm") : ""
        return hourString + minuteString + ampmString
    }

    func areOnDifferentDays(_ a: Date, _ b: Date) -> Bool {
        let ay = component(.year, from: a)
        let am = component(.month, from: a)
        let ad = component(.day, from: a)

        let by = component(.year, from: b)
        let bm = component(.month, from: b)
        let bd = component(.day, from: b)

        return ay != by || am != bm || ad != bd
    }

    func daysBetween(_ a: Date, and b: Date) -> Int {
        let aYear = component(Calendar.Component.year, from: a)
        let aDayOfYear = ordinality(of: Calendar.Component.day, in: Calendar.Component.year, for: a)!

        let bYear = component(Calendar.Component.year, from: b)
        let bDayOfYear = ordinality(of: Calendar.Component.day, in: Calendar.Component.year, for: b)!

        return ((bYear - aYear) * 365) + (bDayOfYear - aDayOfYear)
    }

    func todayAt(hour: Int, minute: Int) -> Date {
        return self.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
    }

    func todayAtRandom(after: Date? = nil) -> Date {
        var components: DateComponents!
        if let after = after {
            let atLeastHour = self.component(Calendar.Component.hour, from: after)
            components = DateComponents(hour: atLeastHour+Int.random(24-atLeastHour-1)+1, minute: Int.random(60))
        } else {
            components = DateComponents(hour: Int.random(24), minute: Int.random(60))
        }
        return self.date(from: components)!
    }

    func isDate(_ a: Date, before b: Date) -> Bool {
        switch compare(a, to: b, toGranularity: .minute) {
        case .orderedAscending:
            return true
        default:
            return false
        }
    }

    func isDate(_ a: Date, after b: Date) -> Bool {
        switch compare(a, to: b, toGranularity: .minute) {
        case .orderedDescending:
            return true
        default:
            return false
        }
    }
}
