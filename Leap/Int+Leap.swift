//
//  Int+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


extension Int {
    static func random(_ upperBound: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upperBound)))
    }

    var durationString: String {
        return TimeInterval(self).durationString
    }

    func pluralize(string: String, suffix: String = "s") -> String {
        switch self {
        case 1:
            return string
        default:
            return "\(string)\(suffix)"
        }
    }
}
