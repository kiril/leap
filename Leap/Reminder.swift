//
//  Reminder.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Reminder: _TemporalBase, Temporality, CalendarLinkable, Alarmable {
    dynamic var event: Event?
    dynamic var location: Location?
    dynamic var geoFence: GeoFence?
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var timeUTC: Int = 0

    var date: Date? { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }
    var time: TimeInterval { return Double(startTime) }

    var startDate: Date { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }

    override static func indexedProperties() -> [String] {
        return ["location.id", "startTime", "participants", "statusString"]
    }

    var duration: TimeInterval {
        guard startTime != 0, endTime != 0 else {
            return 0.0
        }
        return Double(endTime - startTime)
    }

    static func between(_ starting: Date, and before: Date) -> Results<Reminder> {
        let predicate = NSPredicate(format: "statusString = %@ AND startTime >= %d AND startTime < %d", ObjectStatus.active.rawValue, starting.secondsSinceReferenceDate, before.secondsSinceReferenceDate)
        return Realm.user().objects(Reminder.self).filter(predicate).sorted(byKeyPath: "startTime")
    }

    func isDuplicateOfExisting() -> Bool {
        guard startTime != 0 else {
            return false
        }
        let query = Realm.user().objects(Reminder.self).filter("title = %@ AND startTime = %d", title, startTime)
        return query.first != nil
    }

    static func on(_ day: GregorianDay) -> Results<Reminder> {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        return between(start, and: end)
    }
}
