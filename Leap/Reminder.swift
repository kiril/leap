//
//  Reminder.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum ReminderType: String {
    case day
    case time
    case event
    case unknown
}

class Reminder: _TemporalBase, Temporality, Originating, CalendarLinkable, Alarmable, Fuzzy {
    dynamic var event: Event?
    dynamic var location: Location?
    dynamic var geoFence: GeoFence?
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var timeUTC: Int = 0
    dynamic var typeString: String = ReminderType.unknown.rawValue

    var type: ReminderType {
        get { return ReminderType(rawValue: typeString)! }
        set { typeString = newValue.rawValue }
    }

    var date: Date? { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }
    var time: TimeInterval { return Double(startTime) }

    var startDate: Date { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }
    var endDate: Date? { return endTime != 0 ? Date(timeIntervalSinceReferenceDate: Double(endTime)) : nil }

    override static func indexedProperties() -> [String] {
        return ["location.id", "startTime", "participants", "statusString", "hash"]
    }

    var duration: TimeInterval {
        guard startTime != 0, endTime != 0 else {
            return 0.0
        }
        return Double(endTime - startTime)
    }



    func isDetachedForm(of series: Series) -> Bool {

        if !series.recurs(exactlyAt: startDate, ignoreActiveRange: true) {
            return true
        }

        if title != series.template.title {
            return true
        }

        return series.status != self.status
    }

    func calculateFuzzyHash() -> Int {
        return "\(title)_\(startTime)_\(endTime)_\(participants)".hashValue
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

    static func between(_ starting: Date, and before: Date) -> Results<Reminder> {
        let start = starting.secondsSinceReferenceDate
        let end = before.secondsSinceReferenceDate
        let active = ObjectStatus.active.rawValue
        let predicate = NSPredicate(format: "statusString = %@ AND ((startTime >= %d AND startTime < %d) OR (startTime < %d AND endTime >= %d))", active, start, end, start, start)
        //let predicate = NSPredicate(format: "statusString = %@ AND ((startTime >= %d AND startTime < %d) OR (endTime >= %d AND endTime <= %d) OR (startTime < %d AND endTime > %d))", status.rawValue, start, end, start, end, start, end)
        return Realm.user().objects(Reminder.self).filter(predicate).sorted(byKeyPath: "startTime")
    }
}
