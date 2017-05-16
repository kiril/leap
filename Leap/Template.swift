//
//  Template.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Template: LeapModel, Originating, Particible, Alarmable, CalendarLinkable {
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
    dynamic var reminderTypeString: String?
    dynamic var event: Event?

    let channels = List<Channel>()

    let participants = List<Participant>()
    let alarms = List<Alarm>()
    let linkedCalendarIds = List<StringWrapper>()

    func clone() -> Template {
        let copy = Template(value: self)
        copy.id = UUID().uuidString
        return copy
    }

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }

    var reminderType: ReminderType {
        get { return ReminderType(rawValue: reminderTypeString!)! }
        set { reminderTypeString = newValue.rawValue }
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
                                   "linkedCalendarIds": linkedCalendarIds,
                                   "typeString": reminderTypeString,
                                   "event": event,
                                   "originString": originString]
        return Reminder(value: data)
    }

    func range(in inputRange: TimeRange) -> TimeRange? {
        guard let start = startTime(in: inputRange) else { return nil }
        guard let end = endTime(in: inputRange, startTime: start) else { return nil }
        return TimeRange(start: start, end: end)
    }

    func startTime(in range: TimeRange) -> Date? {
        return startTime(between: range.start, and: range.end)
    }

    func startTime(between start: Date, and end: Date) -> Date? {
        if Calendar.current.component(.minute, from: start) == startMinute &&
            Calendar.current.component(.hour, from: start) == startHour {
            return start < end ? start : nil
        }
        let possibility = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: start)!

        guard possibility < end && possibility > start else {
            return nil
        }
        return possibility
    }

    func endTime(in range: TimeRange, startTime: Date? = nil) -> Date? {
        return endTime(between: range.start, and: range.end, startTime: startTime)
    }


    func endTime(between start: Date, and end: Date, startTime: Date? = nil) -> Date? {
        if let start = startTime ?? self.startTime(between: start, and: end) {
            return Calendar.current.date(byAdding: .minute, value: durationMinutes, to: start)!
        }
        return nil
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

        return Event(value: ["id": id,
                             "title": title,
                             "detail": detail,
                             "locationString": locationString,
                             "agenda": agenda?.copy(),
                             "modalityString": modalityString,
                             "startTime": startDate.secondsSinceReferenceDate,
                             "seriesId": seriesId,
                             "participants": participants,
                             "alarms": alarms,
                             "linkedCalendarIds": linkedCalendarIds,
                             "originString": originString,
                             "endTime": endDate.secondsSinceReferenceDate])
    }
}
