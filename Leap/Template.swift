//
//  Template.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Template: LeapModel {
    dynamic var title: String = ""
    dynamic var detail: String?
    dynamic var locationString: String?
    dynamic var agenda: Checklist?
    dynamic var modalityString: String = EventModality.inPerson.rawValue
    dynamic var startHour: Int = 0
    dynamic var startMinute: Int = 0
    dynamic var durationMinutes: Int = 0
    dynamic var leadTime: Double = 0.0
    dynamic var trailTime: Double = 0.0

    let alarms = List<Alarm>()
    let channels = List<Channel>()

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }

    func event(onDayOf date: Date, in series: Series, id: String? = nil) -> Event? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let startComponents = DateComponents(year: year, month: month, day: day, hour: startHour, minute: startMinute)

        var endHour = startHour
        var endMinute = startMinute + durationMinutes
        if endMinute >= 60 {
            endHour += Int(Float(endMinute)/60.0)
            endMinute = endMinute % 60
        }
        let endComponents = DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMinute)

        let start = Calendar.current.date(from: startComponents)
        let end = Calendar.current.date(from: endComponents)

        guard let startDate = start, let endDate = end else {
            return nil
        }
        let data: ModelInitData = ["id": id,
                                   "title": title,
                                   "detail": detail,
                                   "locationString": locationString,
                                   "agenda": agenda,
                                   "modalityString": modalityString,
                                   "startTime": startDate.secondsSinceReferenceDate,
                                   "series_id": series.id,
                                   "endTime": endDate.secondsSinceReferenceDate]
        let event = Event(value: data)
        try! Realm.temp().write {
            Realm.temp().add(event, update: true)
        }
        return event
    }
}
