//
//  Recurrence.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum Frequency: String {
    case unknown = "unknown"
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    case yearly  = "yearly"
}

enum DayOfWeek: Int {
    case sunday    = 1
    case monday    = 2
    case tuesday   = 3
    case wednesday = 4
    case thursday  = 5
    case friday    = 6
}

class RecurrenceDay: Object {
    dynamic var id: Int = 0
    dynamic var dayOfWeekRaw: Int = DayOfWeek.sunday.rawValue
    dynamic var week: Int = 0 // 1-indexed

    var dayOfWeek: DayOfWeek {
        get { return DayOfWeek(rawValue: dayOfWeekRaw)! }
        set { dayOfWeekRaw = newValue.rawValue }
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    static func of(day: DayOfWeek, in week: Int) -> RecurrenceDay {
        return RecurrenceDay(value: ["id": week*1000 + day.rawValue,
                                     "dayOfWeekRaw": day.rawValue,
                                     "week": week])
    }
}


// NOTE: can you indicate attendence to all future?
// Can you make it such that editing doesn't by default even touch the recurrence?
class Recurrence: LeapModel {
    dynamic var startHour: Int = 0
    dynamic var startMinute: Int = 0
    dynamic var durationMinutes: Int = 0
    dynamic var leadTime: Double = 0.0
    dynamic var trailTime: Double = 0.0
    dynamic var count: Int = 0
    dynamic var frequencyRaw: String = Frequency.unknown.rawValue
    dynamic var interval: Int = 0
    dynamic var referenceEvent: Event?
    dynamic var weekStartRaw: Int = DayOfWeek.sunday.rawValue

    let daysOfWeek = List<RecurrenceDay>()
    let daysOfMonth = List<IntWrapper>()
    let daysOfYear = List<IntWrapper>()
    let weeksOfYear = List<IntWrapper>()
    let monthsOfYear = List<IntWrapper>()
    let setPositions = List<IntWrapper>()

    var weekStart: DayOfWeek {
        get { return DayOfWeek(rawValue: weekStartRaw)! }
        set { weekStartRaw = newValue.rawValue }
    }

    var frequency: Frequency {
        get { return Frequency(rawValue: frequencyRaw)! }
        set { frequencyRaw = newValue.rawValue }
    }

    func recursBetween(_ startDate: Date, and endDate: Date) -> Bool {
        // 
        return false
    }
}
