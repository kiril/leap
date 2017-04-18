//
//  Series.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum SeriesType: String {
    case event
    case reminder

    static func of(_ tm: Temporality) -> SeriesType {
        switch tm {
        case is Event:
            return .event
        case is Reminder:
            return .reminder
        default:
            fatalError("Series doesn't support \(type(of:tm)) types")
        }
    }
}

class Series: LeapModel {
    dynamic var creator: Person?
    dynamic var title: String = ""
    dynamic var template: Template?
    dynamic var recurrence: Recurrence?
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var typeString: String = SeriesType.event.rawValue

    let events = LinkingObjects(fromType: Event.self, property: "series")

    static func by(id: String) -> Series? {
        return fetch(id: id)
    }

    var startDate: Date {
        return Date(timeIntervalSinceReferenceDate: TimeInterval(self.startTime))
    }

    var endDate: Date? {
        return self.endTime > 0 ? Date(timeIntervalSinceReferenceDate: TimeInterval(self.endTime)) : nil
    }

    var type: SeriesType {
        get { return SeriesType(rawValue: self.typeString)! }
        set { self.typeString = newValue.rawValue }
    }

    public static func series(_ title: String, startingOn startDate: Date, endingOn endDate: Date? = nil) -> Series {
        return Series(value: ["title": title,
                              "startTime": startDate.secondsSinceReferenceDate,
                              "endTime": endDate?.secondsSinceReferenceDate ?? 0])
    }

    /**
     * Note: The general usage should be:
     *   if series.recursBetween(...), let tm = series.stub(on: date) {
     *       ...
     *   }
     */
    func recursBetween(_ startDate: Date, and endDate: Date) -> Bool {
        guard startTime <= endDate.secondsSinceReferenceDate &&
            (endTime == 0 || endTime > startDate.secondsSinceReferenceDate) else {
            return false
        }
        var date:Date? = startDate
        while let d = date, d.secondsSinceReferenceDate < endDate.secondsSinceReferenceDate {
            if recurrence!.recursOn(d, for: self) {
                return true
            }
            date = Calendar.current.date(byAdding: DateComponents(day: 1), to: d)
        }
        return false
    }

    func event(between start: Date, and end: Date) -> Temporality? {
        if self.type == .reminder {
            return nil
        }

        let eventId = "\(id)-\(start.secondsSinceReferenceDate)"
        if let event = Event.by(id: eventId) {
            return gregorianCalendar.isDate(event.startDate, betweenInclusive: start, and: end) ? event : nil
        }
        let firstTry = template!.event(onDayOf: start, id: eventId)
        if let firstTry = firstTry,
            Calendar.current.isDate(firstTry.startDate, betweenInclusive: start, and: end),
            self.recurrence!.recursOn(firstTry.startDate, for: self) {
            return firstTry
        }
        let secondTry = template!.event(onDayOf: end, id: eventId)
        if let secondTry = secondTry,
            Calendar.current.isDate(secondTry.startDate, betweenInclusive: start, and: end),
            self.recurrence!.recursOn(secondTry.startDate, for: self) {
            return secondTry
        }
        return nil
    }

    static func on(_ day: GregorianDay) -> Results<Series> {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        return between(start, and: end)
    }

    static func between(_ starting: Date, and before: Date) -> Results<Series> {
        return Realm.user().objects(Series.self).filter("statusString = %@ AND startTime < %d AND (endTime == 0 OR endTime >= %d)", ObjectStatus.active.rawValue, before.secondsSinceReferenceDate, starting.secondsSinceReferenceDate)
    }

    override static func indexedProperties() -> [String] {
        return ["statusString", "startTime", "endTime"]
    }
}
