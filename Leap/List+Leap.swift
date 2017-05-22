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

    func append(_ weekday: Weekday) {
        self.append(IntWrapper.of(weekday.rawValue))
    }

    func append(_ ordinal: OrdinalWeekday) {
        self.append(IntWrapper.of(ordinal.encode()))
    }

    func contains(_ weekday: Weekday) -> Bool {
        return self.contains(IntWrapper.of(weekday.rawValue))
    }

    func contains(_ ordinal: OrdinalWeekday) -> Bool {
        return self.contains(IntWrapper.of(ordinal.encode()))
    }

    func hasEqualContents(to other: List<IntWrapper>) -> Bool {
        guard self.count == other.count else { return false }
        for (i, e) in self.enumerated() {
            if e != other[i] {
                return false
            }
        }
        return true
    }
}
