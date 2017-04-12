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
    dynamic var template: EventTemplate?
    dynamic var recurrence: Recurrence?
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0

    let events = LinkingObjects(fromType: Event.self, property: "series")

    static func by(id: String) -> Series? {
        return fetch(id: id)
    }

    static func on(_ day: GregorianDay) -> [Series] {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        return between(start, and: end)
    }

    static func between(_ starting: Date, and before: Date) -> [Series] {
        var query = Realm.user().objects(Series.self)
        query = query.filter("startTime < %d AND endTime > %d", before.secondsSinceReferenceDate, starting.secondsSinceReferenceDate)
        var matches: [Series] = []
        for series in query {
            if series.recurrence!.recursBetween(starting, and: before) {
                matches.append(series)
            }
        }
        return matches
    }

    static func stub(on date: Date) -> Temporality? {
        return nil
    }
}
