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
}
