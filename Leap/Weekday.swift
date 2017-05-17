//
//  Weekday.swift
//  Leap
//
//  Created by Kiril Savino on 5/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

enum Weekday: Int {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var gregorianIndex: Int {
        return rawValue
    }

    static func from(gregorian: Int) -> Weekday {
        return Weekday(rawValue: gregorian)!
    }
}
