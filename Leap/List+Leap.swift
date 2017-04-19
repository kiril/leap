//
//  List+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/13/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension List where T == IntWrapper {
    func contains(_ int: Int) -> Bool {
        for wrapper in self {
            if wrapper.raw == int {
                return true
            }
        }
        return false
    }

    func append(_ int: Int) {
        self.append(IntWrapper.of(int))
    }
}

extension List where T == RecurrenceDay {

    func contains(day: DayOfWeek) -> Bool {
        for rd in self {
            if rd.dayOfWeek == day {
                return true
            }
        }
        return false
    }

    func contains(day: DayOfWeek, week: Int) -> Bool {
        for rd in self {
            if rd.dayOfWeek == day && rd.week == week {
                return true
            }
        }
        return false
    }
}
