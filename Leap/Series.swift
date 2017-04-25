//
//  Series.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

let reminderQueue = DispatchQueue(label: "reminder.materialize")
let eventQueue = DispatchQueue(label: "event.materialize")

class Series: LeapModel {
    dynamic var creator: Person?
    dynamic var title: String = ""
    dynamic var template: Template!
    dynamic var recurrence: Recurrence!
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var typeString: String = CalendarItemType.event.rawValue
    dynamic var lastRecurrenceDay: Date?
    dynamic var originString: String = Origin.unknown.rawValue

    static func by(id: String) -> Series? {
        return fetch(id: id)
    }

    var startDate: Date {
        return Date(timeIntervalSinceReferenceDate: TimeInterval(self.startTime))
    }

    var endDate: Date? {
        return self.endTime > 0 ? Date(timeIntervalSinceReferenceDate: TimeInterval(self.endTime)) : nil
    }

    var type: CalendarItemType {
        get { return CalendarItemType(rawValue: self.typeString)! }
        set { self.typeString = newValue.rawValue }
    }

    public static func series(_ title: String, startingOn startDate: Date, endingOn endDate: Date? = nil) -> Series {
        return Series(value: ["title": title,
                              "startTime": startDate.secondsSinceReferenceDate,
                              "endTime": endDate?.secondsSinceReferenceDate ?? 0])
    }

    func updateStartTimeIfEarlier(_ time: Int) {
        if time < startTime {
            startTime = time
            calculateLastRecurrenceDay()
        }
    }

    func calculateLastRecurrenceDay() {
        guard recurrence!.count > 0 else {
            return
        }

        let realm = Realm.user()
        var lastDay: Date?
        let rec = recurrence!
        let maxRecurrences = rec.count

        // idea:
        // you can count days/weeks, modulo contraints,
        // and then skip to that week and know how many occurrences,
        // and thus were you are in the contrain list, and figure out what
        // that last matching day would be

        switch recurrence!.frequency {
        case .daily:
            // I don't think Daily can work any other way...
            lastDay = Calendar.current.date(byAdding: .day, value: maxRecurrences-1, to: startDate)

        case .weekly:
            let occurrencesPerWeek = rec.daysOfWeek.count
            let fullWeeks = maxRecurrences / occurrencesPerWeek
            let remainder = maxRecurrences % occurrencesPerWeek
            let endOfLastFullWeek = Calendar.current.date(byAdding: .day, value: fullWeeks*7, to: startDate)!
            if remainder == 0 {
                lastDay = endOfLastFullWeek // this overshoots, but not by enough to accidentally include any extra events
            } else {
                var day = Calendar.current.dayAfter(endOfLastFullWeek)
                let endOfSubsequentWeek = Calendar.current.date(byAdding: .day, value: 7, to: endOfLastFullWeek)!
                var timesRecurred = fullWeeks * occurrencesPerWeek
                while day < endOfSubsequentWeek && timesRecurred < maxRecurrences {
                    if rec.recursOn(day, for: self) {
                        timesRecurred += 1
                    }
                    day = Calendar.current.dayAfter(day)
                }
                lastDay = day
            }

        case .monthly:
            if rec.daysOfMonth.count > 0 {
                let occurrencesPerMonth = rec.daysOfMonth.count
                let fullMonths = maxRecurrences / occurrencesPerMonth
                let remainder = maxRecurrences % occurrencesPerMonth
                let endOfLastFullMonth = Calendar.current.date(byAdding: .month, value: fullMonths, to: startDate)!
                if remainder == 0 {
                    lastDay = endOfLastFullMonth // this overshoots, but not by enough to accidentally include any extra events
                } else {
                    var day = Calendar.current.dayAfter(endOfLastFullMonth)
                    let endOfSubsequentMonth = Calendar.current.date(byAdding: .month, value: 1, to: endOfLastFullMonth)!
                    var timesRecurred = fullMonths * occurrencesPerMonth
                    while day < endOfSubsequentMonth && timesRecurred < maxRecurrences {
                        if rec.recursOn(day, for: self) {
                            timesRecurred += 1
                        }
                        day = Calendar.current.dayAfter(day)
                    }
                    lastDay = day
                }
            }
            // TODO: there are other cases, but they're harder and brute force is my friend


        case .yearly:
            if rec.daysOfYear.count > 0 {

                let occurrencesPerYear = rec.daysOfYear.count
                let fullYears = maxRecurrences / occurrencesPerYear
                let remainder = maxRecurrences % occurrencesPerYear
                let endOfLastFullYear = Calendar.current.date(byAdding: .year, value: fullYears, to: startDate)!
                if remainder == 0 {
                    lastDay = endOfLastFullYear // this overshoots, but not by enough to accidentally include any extra events
                } else {
                    var day = Calendar.current.dayAfter(endOfLastFullYear)
                    let endOfSubsequentYear = Calendar.current.date(byAdding: .year, value: 1, to: endOfLastFullYear)!
                    var timesRecurred = fullYears * occurrencesPerYear
                    while day < endOfSubsequentYear && timesRecurred < maxRecurrences {
                        if rec.recursOn(day, for: self) {
                            timesRecurred += 1
                        }
                        day = Calendar.current.dayAfter(day)
                    }
                    lastDay = day
                }

            } else if rec.monthsOfYear.count == 1 {
                if rec.daysOfMonth.count == 1 || rec.daysOfWeek.count == 1 {
                    let yearsOut = maxRecurrences
                    let lastYearStart = Calendar.current.date(byAdding: .year, value: yearsOut-1, to: startDate)!
                    let firstOfMonth = Calendar.current.date(bySetting: .day, value: 1, of: lastYearStart)!

                    let lastMonthStart = Calendar.current.date(bySetting: .month, value: rec.monthsOfYear[0].raw, of: firstOfMonth)!
                    let lastMonthEnd = Calendar.current.date(byAdding: .month, value: 1, to: lastMonthStart)!

                    var day = lastMonthStart
                    while day < lastMonthEnd {
                        if rec.recursOn(day, for: self) {
                            lastDay = day
                            break
                        }
                        day = Calendar.current.dayAfter(day)
                    }
                }
            }
            break

        case .unknown:
            fatalError("No real recurrence should have an unknown frequency")
        }

        if lastDay == nil {
            if maxRecurrences > 1000000 {
                fatalError("OMG really??? \(maxRecurrences) is just too many.")
            }
            // Brute Force!
            var day = startDate
            var recurrences = 0
            while recurrences < maxRecurrences {
                if rec.recursOn(day, for: self) {
                    recurrences += 1
                }
                day = Calendar.current.dayAfter(day)
            }
            lastDay = day
        }

        try! realm.safeWrite {
            self.lastRecurrenceDay = lastDay!
            realm.add(self, update: true)
        }
    }

    /**
     * Note: The general usage should be:
     *   if series.recursBetween(...), let tm = series.stub(on: date) {
     *       ...
     *   }
     */
    func recursBetween(_ startDate: Date, and endDate: Date) -> Bool {
        if recurrence!.count > 0 && lastRecurrenceDay == nil {
            calculateLastRecurrenceDay()
        }
        guard startTime <= endDate.secondsSinceReferenceDate &&
            (endTime == 0 || endTime > startDate.secondsSinceReferenceDate) else {
            return false
        }
        guard lastRecurrenceDay == nil || startDate <= lastRecurrenceDay! else { // this is for count-based max recurrences
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

    func startTime(between start: Date, and end: Date) -> Date? {
        if Calendar.universalGregorian.component(.minute, from: start) == template.startMinute &&
            Calendar.universalGregorian.component(.hour, from: start) == template.startHour {
            return start < end ? start : nil
        }
        let minuteSet = Calendar.universalGregorian.date(bySetting: .minute, value: template.startMinute, of: start)!
        let possibility = Calendar.universalGregorian.date(bySetting: .hour, value: template.startHour, of: minuteSet)!

        guard possibility < end else {
            return nil
        }
        return possibility
    }

    func idFor(start: Date) -> String {
        let year = Calendar.universalGregorian.component(.year, from: start)
        let month = Calendar.universalGregorian.component(.month, from: start)
        let day = Calendar.universalGregorian.component(.day, from: start)
        let hour = Calendar.universalGregorian.component(.hour, from: start)
        let minute = Calendar.universalGregorian.component(.minute, from: start)
        return "\(id)-\(year).\(month).\(day).\(hour):\(minute)"
    }

    func isExactRecurrence(date: Date) -> Bool {
        if Calendar.universalGregorian.component(.hour, from: date) == template.startHour &&
            Calendar.universalGregorian.component(.minute, from: date) == template.startMinute &&
            recurrence.recursOn(date, for: self) {
            return true

        }
        return false
    }

    func event(between start: Date, and end: Date) -> Event? {
        guard self.type == .event else {
            return nil
        }

        guard let eventStart = startTime(between: start, and: end), recurrence.recursOn(eventStart, for: self) else {
            return nil
        }

        let eventId = idFor(start: eventStart)

        eventQueue.sync {
            if let _ = Event.by(id: eventId) {
                return
            }

            if let event = template.event(onDayOf: eventStart, id: eventId),
                Calendar.universalGregorian.isDate(event.startDate, betweenInclusive: start, and: end) &&
                    self.recurrence.recursOn(event.startDate, for: self) {
                event.insert()
            }
        }

        if let event = Event.by(id: eventId) {
            return Calendar.universalGregorian.isDate(event.startDate, betweenInclusive: start, and: end) ? event : nil
        }
        
        return nil
    }

    func reminder(between start: Date, and end: Date) -> Reminder? {
        guard self.type == .reminder else {
            return nil
        }

        guard let reminderStart = startTime(between: start, and: end), recurrence.recursOn(reminderStart, for: self) else {
            return nil
        }

        let reminderId = self.idFor(start: reminderStart)

        reminderQueue.sync {
            if let _ = Reminder.by(id: reminderId) {
                return
            }

            if let reminder = template.reminder(onDayOf: reminderStart, id: reminderId),
                Calendar.universalGregorian.isDate(reminder.startDate, betweenInclusive: start, and: end) &&
                self.recurrence.recursOn(reminder.startDate, for: self) {
                reminder.insert()
            }
        }

        if let reminder = Reminder.by(id: reminderId) {
            return Calendar.universalGregorian.isDate(reminder.startDate, betweenInclusive: start, and: end) ? reminder : nil
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

    static func by(title: String) -> Series? {
        return Realm.user().objects(Series.self).filter("title = %@ AND statusString = %@", title, ObjectStatus.active.rawValue).first
    }
}
