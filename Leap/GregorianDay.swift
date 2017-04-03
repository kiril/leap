//
//  GregorianDay.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

struct GregorianDay {
    // does this need to be gregorian? Do day ids need to e independent of a calendar view? (i.e. are they stored / transmitted at all?

    private let secondsInADay : Double = 86400
    let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Foundation.TimeZone(abbreviation: "GMT")!
        return cal
    }()

    private let daysSinceEpoch: Int
    var id : Int {
        return daysSinceEpoch + 1 // treating epoch day should as index 1 for the moment
    }

    var day: Int
    var month: Int
    var year: Int

    var components: DateComponents {
        return DateComponents(year: year,
                              month: month,
                              day: day)
    }

    var dayAfter: GregorianDay {
        return GregorianDay(id: id + 1)
    }

    var dayBefore: GregorianDay {
        return GregorianDay(id: id - 1)
    }

    init(id: Int) {
        daysSinceEpoch = id - 1 // treating epoch day as index 1 for the moment

        let seconds: TimeInterval = (Double(daysSinceEpoch) * secondsInADay)

        let dayDate = Date(timeIntervalSince1970: seconds)
        let components = calendar.dateComponents([.day, .month, .year], from: dayDate)

        day = components.day!
        month = components.month!
        year = components.year!
    }


    // initialize a day using gregorian day, month, and year
    init?(day: Int, month: Int, year: Int) {
        self.day = day
        self.month = month
        self.year = year

        let components = DateComponents(calendar: calendar,
                                        year: year,
                                        month: month,
                                        day: day)

        guard let dayDate = calendar.date(from: components) else { return nil }

        let daysSinceEpoch = dayDate.timeIntervalSince1970 / secondsInADay
        self.daysSinceEpoch = Int(daysSinceEpoch)
    }
}

extension Calendar {
    func startOfDay(for day: GregorianDay) -> Date {
        return startOfDay(for: date(from: day.components)!)
    }

    func dayOfTheWeek(for day: GregorianDay) -> Int {
        let date = self.date(from: day.components)!
        return component(.weekday, from: date)
    }

    func month(for day: GregorianDay) -> Int {
        let date = self.date(from: day.components)!
        return component(.month, from: date)
    }

    var today: GregorianDay {
        var gregorianTimeAdjustedCalendar = Calendar(identifier: .gregorian)
        gregorianTimeAdjustedCalendar.timeZone = self.timeZone

        let components = dateComponents([.day, .month, .year], from: Date())

        let day = GregorianDay(day: components.day!,
                               month: components.month!,
                               year: components.year!)!

        return day
    }

    var tomorrow: GregorianDay {
        return today.dayAfter
    }

    var yesterday: GregorianDay {
        return today.dayBefore
    }
}
