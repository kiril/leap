//
//  Weekday.swift
//  Leap
//
//  Created by Kiril Savino on 5/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

enum Weekday: Int {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var gregorianIndex: Int {
        return rawValue
    }

    var name: String {
        switch self {
        case .sunday:
            return "Sunday"
        case .monday:
            return "Monday"
        case .tuesday:
            return "Tuesday"
        case .wednesday:
            return "Wednesday"
        case .thursday:
            return "Thursday"
        case .friday:
            return "Friday"
        case .saturday:
            return "Saturday"
        }
    }

    func week(_ week: Int) -> OrdinalWeekday {
        return OrdinalWeekday(self, week)
    }

    static func of(_ date: Date) -> Weekday {
        return from(gregorian: Calendar.current.component(.weekday, from: date))
    }

    static func from(gregorian: Int) -> Weekday {
        switch gregorian {
        case GregorianSunday:
            return .sunday
        case GregorianMonday:
            return .monday
        case GregorianTuesday:
            return .tuesday
        case GregorianWednesday:
            return .wednesday
        case GregorianThursday:
            return .thursday
        case GregorianFriday:
            return .friday
        case GregorianSaturday:
            return .saturday
        default:
            fatalError("Invalid gregorian weekday \(gregorian)")
        }
    }

    static func name(of gregorian: Int) -> String {
        return from(gregorian: gregorian).name
    }
}

struct OrdinalWeekday {
    let ordinal: Int
    let weekday: Weekday

    init(_ w: Weekday, _ o: Int) {
        ordinal = o
        weekday = w
    }

    func encode() -> Int {
        switch ordinal {
        case 0:
            return weekday.rawValue
        case 1...Int.max:
            return (ordinal * 1000) + weekday.rawValue
        default:
            return (ordinal * 1000) - weekday.rawValue
        }
    }

    static func decode(_ i: Int) -> OrdinalWeekday {
        switch i {
        case 1..<8:
            return OrdinalWeekday(Weekday.from(gregorian: i), 0)
        default:
            return OrdinalWeekday(Weekday.from(gregorian: abs(i % 1000)), i / 1000)
        }
    }
}
