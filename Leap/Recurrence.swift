//
//  Recurrence.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum Frequency: String {
    case unknown = "unknown"
}


// NOTE: can you indicate attendence to all future?
// NOTE: is detachment really the right model?
// Can you make it such that editing doesn't by default even touch the recurrence?
class Recurrence: LeapModel {
    dynamic var startTime: Date?
    dynamic var endTime: Date?
    dynamic var leadTime: Double = 0.0
    dynamic var trailTime: Double = 0.0
    dynamic var count: Int = 0
    dynamic var frequencyString: String = Frequency.unknown.rawValue
    dynamic var interval: Int = 0
    dynamic var referenceEvent: Event?

    var frequency: Frequency {
        get { return Frequency(rawValue: frequencyString)! }
        set { frequencyString = newValue.rawValue }
    }
}
