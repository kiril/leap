//
//  Alarm.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

enum ProximityTrigger: String {
    case enter = "enter"
    case leave = "leave"
}


enum AlarmType: String {
    case absolute = "absolute"
    case relative = "relative"
    case location = "location"
}

class Alarm: LeapModel {
    dynamic var typeString: String = AlarmType.absolute.rawValue
    dynamic var absoluteTime: Date?
    dynamic var relativeOffset: TimeInterval = 0
    dynamic var geoFence: GeoFence?
    dynamic var geoTriggerString: String?

    var geoTrigger: ProximityTrigger? {
        get { return ProximityTrigger(rawValue: geoTriggerString ?? "") }
        set { geoTriggerString = newValue?.rawValue }
    }
}
