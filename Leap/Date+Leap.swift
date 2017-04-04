//
//  Date+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/3/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension Date {
    static var millisecondsSinceReferenceDate: Int {
        return Int(Date.timeIntervalSinceReferenceDate * 1000)
    }

    var millisecondsSinceReferenceDate: Int {
        return Int(self.timeIntervalSinceReferenceDate * 1000)
    }
}
