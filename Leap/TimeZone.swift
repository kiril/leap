//
//  TimeZone.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class TimeZone: LeapModel {
    dynamic var descriptionString: String = ""

    static func from(_ tz: Foundation.TimeZone) -> TimeZone {
        return TimeZone(value: ["id": tz.identifier,
                                "descriptionString": tz.description])
    }

    func toTimeZone() -> Foundation.TimeZone {
        return Foundation.TimeZone(identifier: self.id)!
    }
}
