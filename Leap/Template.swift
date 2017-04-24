//
//  Template.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Template: LeapModel, Particible, Alarmable, Linkable {
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
    dynamic var isTentative: Bool = false
    dynamic var originString: String = Origin.unknown.rawValue
    dynamic var seriesId: String?

    let channels = List<Channel>()

    let participants = List<Participant>()
    let alarms = List<Alarm>()
    let links = List<CalendarLink>()

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }

    func reminder(onDayOf date: Date, id: String? = nil) -> Reminder? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let startComponents = DateComponents(year: year, month: month, day: day, hour: startHour, minute: startMinute)
        let start = Calendar.current.date(from: startComponents)

        guard let startDate = start else {
            return nil
        }

        let data: ModelInitData = ["id": id,
                                   "title": title,
                                   "detail": detail,
                                   "locationString": locationString,
                                   "startTime": startDate.secondsSinceReferenceDate,
                                   "seriesId": seriesId,
                                   "participants": participants,
                                   "alarms": alarms,
                                   "links": links,
                                   "originString": originString]
        let reminder = Reminder(value: data)
        try! Realm.user().safeWrite { // TODO: - store in memory eventually?
            Realm.user().add(reminder)
        }
        return reminder
    }

    func event(onDayOf date: Date, id: String? = nil) -> Event? {
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
                                   "agenda": agenda?.copy(),
                                   "modalityString": modalityString,
                                   "startTime": startDate.secondsSinceReferenceDate,
                                   "seriesId": seriesId,
                                   "participants": participants,
                                   "alarms": alarms,
                                   "links": links,
                                   "originString": originString,
                                   "endTime": endDate.secondsSinceReferenceDate]
        let event = Event(value: data)
        try! Realm.user().safeWrite { // TODO: - store in memory eventually?
            Realm.user().add(event, update: true)
        }
        return event
    }
}
