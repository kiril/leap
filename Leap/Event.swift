//
//  Event.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import RealmSwift
import Foundation


/**
 * Here's our core!
 */
class Event: LeapModel, Temporality {
    dynamic var title: String = ""
    dynamic var detail: String = ""
    dynamic var startTime: Date = Date()
    dynamic var endTime: Date = Date()
    dynamic var sourceCalendars: [LegacyCalendar]?
}
