//
//  Reminder.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Reminder: _TemporalBase, Temporality {
    dynamic var event: Event?
    dynamic var location: Location?
    dynamic var geoFence: GeoFence?
    dynamic var startDate: Date?
    dynamic var endDate: Date?
    dynamic var timeUTC: Int = 0

    var date: Date? { return startDate }

    override static func indexedProperties() -> [String] {
        return ["location.id", "startDate", "participants"]
    }

    var duration: TimeInterval {
        guard let end = endDate, let start = startDate else {
            return 0.0
        }
        return end.timeIntervalSince(start)
    }
}
