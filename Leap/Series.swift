//
//  Series.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Series: LeapModel {
    dynamic var creator: Person?
    dynamic var title: String = ""
    dynamic var template: Template?
    dynamic var recurrence: Recurrence?
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0

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
        while let d = date, d.secondsSinceReferenceDate <= endDate.secondsSinceReferenceDate {
            if recurrence!.recursOn(d, for: self) {
                return true
            }
            date = Calendar.current.date(byAdding: DateComponents(day: 1), to: d)
        }
        return false
    }

    func event(between start: Date, and end: Date) -> Temporality? {
        let eventId = "\(id)-\(start.secondsSinceReferenceDate)"
        if let event = Event.by(id: eventId) {
            return event
        }
        let firstTry = template!.create(onDayOf: start, id: eventId)
        if let firstTry = firstTry, Calendar.current.isDate(firstTry.date!, betweenInclusive: start, and: end) {
            return firstTry
        }
        let secondTry = template!.create(onDayOf: start, id: eventId)
        if let secondTry = secondTry, Calendar.current.isDate(secondTry.date!, betweenInclusive: start, and: end) {
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
        return Realm.user().objects(Series.self).filter("startTime < %d AND (endTime == 0 OR endTime >= %d)", before.secondsSinceReferenceDate, starting.secondsSinceReferenceDate)
    }
}
