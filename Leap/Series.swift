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

class Series: LeapModel, Fuzzy, Originating {
    static let reminderCache = SwiftlyLRU<String,Reminder>(capacity: 100)
    static let eventCache = SwiftlyLRU<String,Event>(capacity: 100)

    dynamic var creator: Person?
    dynamic var title: String = ""
    dynamic var template: Template!
    dynamic var recurrence: Recurrence!
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var typeString: String = CalendarItemType.event.rawValue
    dynamic var lastRecurrenceDay: Date?
    dynamic var originString: String = Origin.unknown.rawValue
    dynamic var engagementString: String = Engagement.none.rawValue
    dynamic var referencing: Series?

    func clone() -> Series {
        let copy = Series(value: self)
        copy.id = UUID().uuidString
        copy.template = copy.template.clone()
        return copy
    }

    var engagement: Engagement {
        get { return Engagement(rawValue: engagementString)! }
        set { engagementString = newValue.rawValue }
    }

    static func by(id: String) -> Series? {
        return fetch(id: id)
    }

    func calculateFuzzyHash() -> Int {
        return "\(title)_\(startTime)_\(template.startHour)_\(template.startMinute)_\(template.durationMinutes)_\(template.participants)".hashValue
    }

    func calculateFuzzyHash(from event: Event) -> Int {
        return "\(event.title)_\(event.startTime)_\(event.startHour)_\(event.startMinute)_\(event.durationMinutes)_\(event.participants)".hashValue
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
                    if rec.recurs(on: day, for: self) {
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
                        if rec.recurs(on: day, for: self) {
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
                        if rec.recurs(on: day, for: self) {
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

                    // TODO: skip to the damned day, given that it's so easy...
                    var day = lastMonthStart
                    while day < lastMonthEnd {
                        if rec.recurs(on: day, for: self) {
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
                if rec.recurs(on: day, for: self) {
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

    func coRecurs(with other: Series, after start: Date) -> Bool {
        guard endTime == other.endTime else { return false }
        ensureLastRecurrenceDayCalculated()
        other.ensureLastRecurrenceDayCalculated()
        guard lastRecurrenceDay == other.lastRecurrenceDay else { return false }
        return recurrence.coRecurs(with: other.recurrence)
    }

    func recurs(on date: Date, ignoreActiveRange: Bool = false) -> Bool {
        return recurs(in: TimeRange.day(of: date))
    }

    func recurs(exactlyAt date: Date, ignoreActiveRange: Bool = false) -> Bool {
        let range = TimeRange.day(of: date)
        guard recurs(in: range, ignoreActiveRange: ignoreActiveRange) else { return false }
        return date == template.startTime(in: range)
    }

    func recurs(in range: TimeRange, ignoreActiveRange: Bool = false) -> Bool {
        return recurs(between: range.start, and: range.end, ignoreActiveRange: ignoreActiveRange)
    }

    func recurs(between start: Date, and end: Date, ignoreActiveRange: Bool = false) -> Bool {
        ensureLastRecurrenceDayCalculated()
        let startSecs = start.secondsSinceReferenceDate
        let endSecs = end.secondsSinceReferenceDate
        guard ignoreActiveRange || (startTime <= endSecs && (endTime == 0 || endTime > startSecs)) else {
            return false
        }
        guard ignoreActiveRange || lastRecurrenceDay == nil || start <= lastRecurrenceDay! else { // this is for count-based max recurrences
            return false
        }

        var date:Date? = startDate
        while let d = date, d.secondsSinceReferenceDate < endSecs {
            if recurrence.recurs(on: d, for: self), let when = template.startTime(in: TimeRange.day(of: d)), when >= start && when < end {
                return true
            }
            date = Calendar.current.dayAfter(d)
        }
        return false
    }

    func ensureLastRecurrenceDayCalculated() {
        if recurrence!.count > 0 && lastRecurrenceDay == nil {
            calculateLastRecurrenceDay()
        }
    }

    func startTime(in range: TimeRange) -> Date? {
        if let when = template.startTime(in: range), recurrence.recurs(on: when, for: self) {
            return when
        }
        return nil
    }

    func generateId(forDayOf date: Date) -> String? {
        return generateId(in: TimeRange.day(of: date))
    }

    func generateId(in range: TimeRange) -> String? {
        guard let date = startTime(in: range) else { return nil }
        return generateId(for: date)
    }

    func generateId(for start: Date) -> String {
        let year = Calendar.universalGregorian.component(.year, from: start)
        let month = Calendar.universalGregorian.component(.month, from: start)
        let day = Calendar.universalGregorian.component(.day, from: start)
        let hour = Calendar.universalGregorian.component(.hour, from: start)
        let minute = Calendar.universalGregorian.component(.minute, from: start)
        return "\(id)-\(year).\(month).\(day).\(hour):\(minute)"
    }

    func isInRange(date: Date) -> Bool {
        return date.secondsSinceReferenceDate >= startTime && (endTime == 0 || date.secondsSinceReferenceDate < endTime)
    }

    func lastRecurringDate(before date: Date) -> Date? {
        guard let last = recurrence.lastRecurringDate(before: date) else { return nil }
        guard isInRange(date: last) else { return nil }
        return last
    }

    func nextRecurringDate(after date: Date) -> Date? {
        guard let next = recurrence.nextRecurringDate(after: date) else { return nil }
        guard isInRange(date: next) else { return nil }
        return next
    }

    func event(in range: TimeRange, withStatus status: [ObjectStatus] = [.active]) -> Event? {
        return event(between: range.start, and: range.end, withStatus: status)
    }

    func event(between start: Date, and end: Date, withStatus status: [ObjectStatus] = [.active]) -> Event? {
        guard self.type == .event else {
            return nil
        }

        // OK, so for multi-day events, this logic is wrong
        // -> if the event is IN PROGRESS at any time on this day, then it's valid...
        // SO:
        // -> check duration of event
        // -> look back from 'start' by that duration when doing the template.startTime()
        guard let eventStart = template.startTime(overlappingRegionBetween: start, and: end), recurrence.recurs(on: eventStart, for: self) else {
            return nil
        }
        let eventId = generateId(for: eventStart)
        if let event = Event.by(id: eventId) {
            if Calendar.universalGregorian.isDate(event.startDate, betweenInclusive: start, and: end) {
                return object(event, ifHasStatus: status)
            } else {
                return nil
            }
        }

        if let event = template.event(onDayOf: eventStart, id: eventId),
            Calendar.universalGregorian.isDate(event.startDate, betweenInclusive: start, and: end) &&
                self.recurrence.recurs(on: event.startDate, for: self) {
            event.engagement = engagement
            event.update()
            return event
        }
        
        return nil
    }

    private func object<T: Auditable>(_ object: T, ifHasStatus status:[ObjectStatus]) -> T? {
        for status in status {
            if object.status == status { return object }
        }
        return nil
    }

    func reminder(between start: Date, and end: Date) -> Reminder? {
        guard self.type == .reminder else {
            return nil
        }

        guard let reminderStart = template.startTime(between: start, and: end), recurrence.recurs(on: reminderStart, for: self) else {
            return nil
        }

        let reminderId = self.generateId(for: reminderStart)

        if let reminder = Reminder.by(id: reminderId) {
            return Calendar.universalGregorian.isDate(reminder.startDate, betweenInclusive: start, and: end) ? reminder : nil
        }

        if let reminder = template.reminder(onDayOf: reminderStart, id: reminderId),
            Calendar.universalGregorian.isDate(reminder.startDate, betweenInclusive: start, and: end) &&
                self.recurrence.recurs(on: reminder.startDate, for: self) {
            reminder.update()
            return reminder
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
        return ["statusString", "startTime", "endTime", "hash"]
    }

    static func by(title: String) -> Series? {
        return Realm.user().objects(Series.self).filter("title = %@ AND statusString = %@", title, ObjectStatus.active.rawValue).first
    }
}
