//
//  Date+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/3/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension Date {
    static var secondsSinceReferenceDate: Int {
        return Int(Date.timeIntervalSinceReferenceDate)
    }

    var secondsSinceReferenceDate: Int {
        return Int(self.timeIntervalSinceReferenceDate)
    }

    func seconds(since date: Date) -> Int {
        return secondsSinceReferenceDate - date.secondsSinceReferenceDate
    }

    func isToday() -> Bool {
        let d = Date()
        if gregorianCalendar.component(.year, from: d) != gregorianCalendar.component(.year, from: self) {
            return false
        }
        if gregorianCalendar.component(.month, from: d) != gregorianCalendar.component(.month, from: self) {
            return false
        }
        if gregorianCalendar.component(.day, from: d) != gregorianCalendar.component(.day, from: self) {
            return false
        }
        return true
    }
}
