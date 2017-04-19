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
        let cal = Calendar.universalGregorian
        
        if cal.component(.year, from: d) != cal.component(.year, from: self) {
            return false
        }
        if cal.component(.month, from: d) != cal.component(.month, from: self) {
            return false
        }
        if cal.component(.day, from: d) != cal.component(.day, from: self) {
            return false
        }
        return true
    }
}
